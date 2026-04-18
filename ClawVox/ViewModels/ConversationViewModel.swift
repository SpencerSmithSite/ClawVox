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

    private let client: OpenClawClient
    private let ttsService = TTSService()
    private let speechService = SpeechService()
    private var streamTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(settings: AppSettings = AppSettings()) {
        self.client = OpenClawClient(settings: settings)
        client.$connectionState
            .assign(to: &$connectionState)
        speechService.$isListening
            .assign(to: &$isListening)
        ttsService.$isSpeaking
            .assign(to: &$isSpeaking)
        speechService.$audioLevel
            .assign(to: &$audioLevel)
        speechService.finalTranscript
            .sink { [weak self] text in
                guard let self else { return }
                self.inputText = text
                self.sendMessage()
            }
            .store(in: &cancellables)
        if !settings.selectedVoiceIdentifier.isEmpty {
            ttsService.configure(voiceIdentifier: settings.selectedVoiceIdentifier)
        }
    }

    func update(settings: AppSettings) {
        client.update(settings: settings)
        if !settings.selectedVoiceIdentifier.isEmpty {
            ttsService.configure(voiceIdentifier: settings.selectedVoiceIdentifier)
        }
    }

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
                ttsService.speak(assistantContent)
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
        messages.removeAll()
    }

    func toggleMic() {
        if speechService.isListening {
            speechService.stopListening()
        } else {
            Task {
                let authorized = await speechService.requestAuthorization()
                guard authorized else { return }
                speechService.startListening()
            }
        }
    }
}
