import Foundation
import Combine

@MainActor
final class ConversationViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var connectionState: ConnectionState = .disconnected
    @Published var isLoading: Bool = false
    @Published var isListening: Bool = false
    @Published var isSpeaking: Bool = false
    @Published var isTTSEnabled: Bool = true
    /// Normalised microphone RMS level (0.0 – 1.0), updated while listening.
    @Published var audioLevel: Float = 0.0

    @Published var savedConversations: [Conversation] = []

    private let client: OpenClawClient
    private let ttsService = TTSService()
    private let openAITTSService = OpenAITTSService()
    private let speechService = SpeechService()
    private let whisperService = WhisperSTTService()
    private var streamTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var currentSettings: AppSettings = AppSettings()
    private let store = ConversationStore()
    private var currentConversationID = UUID()
    private var conversationStartedAt = Date.now

    init(settings: AppSettings = AppSettings()) {
        self.currentSettings = settings
        self.client = OpenClawClient(settings: settings)
        savedConversations = store.conversations

        client.$connectionState
            .assign(to: &$connectionState)

        // isSpeaking is true when either TTS service is active.
        Publishers.CombineLatest(ttsService.$isSpeaking, openAITTSService.$isSpeaking)
            .map { $0 || $1 }
            .assign(to: &$isSpeaking)

        // Merge isListening from both STT services — only one is active at a time.
        Publishers.Merge(
            speechService.$isListening,
            whisperService.$isListening
        )
        .assign(to: &$isListening)

        // Merge audioLevel from both STT services.
        Publishers.Merge(
            speechService.$audioLevel,
            whisperService.$audioLevel
        )
        .assign(to: &$audioLevel)

        // Route final transcripts from both STT services into sendMessage.
        let handleTranscript: (String) -> Void = { [weak self] text in
            guard let self else { return }
            self.inputText = text
            self.sendMessage()
        }
        speechService.finalTranscript
            .sink(receiveValue: handleTranscript)
            .store(in: &cancellables)
        whisperService.finalTranscript
            .sink(receiveValue: handleTranscript)
            .store(in: &cancellables)

        applySettings(settings)
    }

    func update(settings: AppSettings) {
        currentSettings = settings
        client.update(settings: settings)
        applySettings(settings)
    }

    // MARK: - Messaging

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }
        inputText = ""

        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)
        isLoading = true

        let history = messages
        let placeholderID = UUID()
        messages.append(Message(id: placeholderID, role: .assistant, content: ""))

        streamTask = Task {
            var assistantContent = ""
            do {
                for try await token in client.streamChat(messages: history) {
                    assistantContent += token
                    if let idx = messages.firstIndex(where: { $0.id == placeholderID }) {
                        messages[idx] = Message(id: placeholderID, role: .assistant, content: assistantContent)
                    }
                }
            } catch {
                messages.removeAll { $0.id == placeholderID }
            }
            isLoading = false
            if isTTSEnabled && !assistantContent.isEmpty {
                switch currentSettings.ttsProvider {
                case .apple:
                    ttsService.speak(assistantContent)
                case .openai:
                    openAITTSService.speak(assistantContent)
                case .elevenlabs:
                    ttsService.speak(assistantContent)
                }
            }
        }
    }

    func cancelStream() {
        streamTask?.cancel()
        streamTask = nil
        isLoading = false
    }

    func clearConversation() {
        cancelStream()
        ttsService.stop()
        openAITTSService.stop()
        saveCurrentConversationIfNeeded()
        messages.removeAll()
        currentConversationID = UUID()
        conversationStartedAt = .now
    }

    func loadConversation(_ conversation: Conversation) {
        cancelStream()
        ttsService.stop()
        openAITTSService.stop()
        saveCurrentConversationIfNeeded()
        messages = conversation.messages
        currentConversationID = conversation.id
        conversationStartedAt = conversation.startedAt
    }

    func deleteConversation(_ conversation: Conversation) {
        store.delete(conversation)
        savedConversations = store.conversations
    }

    func deleteAllConversations() {
        store.deleteAll()
        savedConversations = []
    }

    private func saveCurrentConversationIfNeeded() {
        guard !messages.isEmpty else { return }
        let convo = Conversation(
            id: currentConversationID,
            title: Conversation.autoTitle(from: messages),
            startedAt: conversationStartedAt,
            messages: messages
        )
        store.save(convo)
        savedConversations = store.conversations
    }

    // MARK: - Voice input

    func toggleMic() {
        // Stop whichever service is currently active.
        if speechService.isListening {
            speechService.stopListening()
            return
        }
        if whisperService.isListening {
            whisperService.stopListening()
            return
        }

        // Start the provider selected in settings.
        switch currentSettings.sttProvider {
        case .apple:
            Task {
                let authorized = await speechService.requestAuthorization()
                guard authorized else { return }
                speechService.startListening()
            }
        case .whisper:
            whisperService.startListening()
        }
    }

    // MARK: - Private

    private func applySettings(_ settings: AppSettings) {
        if !settings.selectedVoiceIdentifier.isEmpty {
            ttsService.configure(voiceIdentifier: settings.selectedVoiceIdentifier)
        }
        whisperService.configure(apiKey: settings.openAIAPIKey)
        openAITTSService.configure(apiKey: settings.openAIAPIKey, voice: settings.openAITTSVoice)
    }
}
