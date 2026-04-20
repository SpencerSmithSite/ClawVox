import Foundation

@MainActor
final class ConversationStore {
    private(set) var conversations: [Conversation] = []
    private let storeURL: URL

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = .prettyPrinted
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init() {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClawVox/conversations", isDirectory: true)
        storeURL = base
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        load()
    }

    func save(_ conversation: Conversation) {
        if let idx = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[idx] = conversation
        } else {
            conversations.insert(conversation, at: 0)
        }
        persist(conversation)
    }

    func delete(_ conversation: Conversation) {
        conversations.removeAll { $0.id == conversation.id }
        try? FileManager.default.removeItem(at: fileURL(for: conversation.id))
    }

    func deleteAll() {
        conversations.removeAll()
        let files = (try? FileManager.default.contentsOfDirectory(
            at: storeURL, includingPropertiesForKeys: nil
        )) ?? []
        files.forEach { try? FileManager.default.removeItem(at: $0) }
    }

    // MARK: - Private

    private func load() {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: storeURL, includingPropertiesForKeys: nil
        ))?.filter { $0.pathExtension == "json" } ?? []

        conversations = files
            .compactMap { try? decoder.decode(Conversation.self, from: Data(contentsOf: $0)) }
            .sorted { $0.startedAt > $1.startedAt }
    }

    private func persist(_ conversation: Conversation) {
        guard let data = try? encoder.encode(conversation) else { return }
        try? data.write(to: fileURL(for: conversation.id), options: .atomic)
    }

    private func fileURL(for id: UUID) -> URL {
        storeURL.appendingPathComponent("\(id).json")
    }
}
