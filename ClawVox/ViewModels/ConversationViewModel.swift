import Foundation
import Combine

@MainActor
final class ConversationViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var connectionState: ConnectionState = .disconnected
    @Published var isLoading: Bool = false

    private let client: OpenClawClient
    private var streamTask: Task<Void, Never>?

    init(settings: AppSettings = AppSettings()) {
        self.client = OpenClawClient(settings: settings)
    }

    func update(settings: AppSettings) {
        client.update(settings: settings)
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
                // Remove the empty placeholder on failure
                messages.removeAll { $0.id == placeholderID }
            }
            isLoading = false
        }
    }

    func cancelStream() {
        streamTask?.cancel()
        streamTask = nil
        isLoading = false
    }

    func clearConversation() {
        cancelStream()
        messages.removeAll()
    }
}
