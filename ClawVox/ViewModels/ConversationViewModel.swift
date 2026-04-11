import Foundation
import Combine

@MainActor
final class ConversationViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var connectionState: ConnectionState = .disconnected
    @Published var isLoading: Bool = false

    // TODO: Inject OpenClawClient and WebSocketClient
    init() {}

    func sendMessage() {
        // TODO: Append user message, call OpenClawClient, append assistant response
    }

    func clearConversation() {
        messages.removeAll()
    }
}
