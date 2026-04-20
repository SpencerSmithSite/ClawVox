import Foundation

struct Conversation: Identifiable, Codable {
    let id: UUID
    var title: String
    let startedAt: Date
    var messages: [Message]

    init(id: UUID = UUID(), title: String = "", startedAt: Date = .now, messages: [Message] = []) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.messages = messages
    }

    static func autoTitle(from messages: [Message]) -> String {
        let text = messages.first(where: { $0.role == .user })?.content ?? ""
        let truncated = String(text.prefix(60))
        return truncated.isEmpty ? "Untitled" : (text.count > 60 ? truncated + "…" : truncated)
    }
}
