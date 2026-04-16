import Foundation
import Combine

// MARK: - Message Types

struct WSMessage: Decodable {
    let type: String
    let payload: WSPayload?
}

struct WSPayload: Decodable {
    let message: String?
    let status: String?
    let code: Int?
}

struct WSOutgoingMessage: Encodable {
    let type: String
}

enum WebSocketError: LocalizedError {
    case notConnected
    case invalidURL
    case encodingError

    var errorDescription: String? {
        switch self {
        case .notConnected: return "WebSocket is not connected."
        case .invalidURL: return "Could not construct a valid WebSocket URL."
        case .encodingError: return "Failed to encode outgoing message."
        }
    }
}

// MARK: - WebSocketClient

@MainActor
final class WebSocketClient: ObservableObject {
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastError: String? = nil
    let messageSubject = PassthroughSubject<WSMessage, Never>()

    private var settings: AppSettings
    private var webSocketTask: URLSessionWebSocketTask?
    private var pingTask: Task<Void, Never>?
    private var receiveTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 8
    private let session = URLSession.shared

    init(settings: AppSettings) {
        self.settings = settings
    }

    func update(settings: AppSettings) {
        self.settings = settings
    }

    // MARK: - Public API

    func connect() {
        connectionState = .connecting
        stopAll()
        reconnectAttempts = 0
        Task { await openConnection() }
    }

    func disconnect() {
        stopAll()
        connectionState = .disconnected
        reconnectAttempts = 0
    }

    func send(_ message: WSOutgoingMessage) async throws {
        guard let task = webSocketTask else { throw WebSocketError.notConnected }
        guard let data = try? JSONEncoder().encode(message),
              let json = String(data: data, encoding: .utf8) else {
            throw WebSocketError.encodingError
        }
        try await task.send(.string(json))
    }

    // MARK: - Private

    private func openConnection() async {
        guard let url = makeWebSocketURL(from: settings.gatewayURL, token: settings.authToken) else {
            connectionState = .error("Invalid gateway URL")
            return
        }

        let task = session.webSocketTask(with: url)
        webSocketTask = task
        task.resume()

        // Send auth message as fallback (spec requirement)
        let authMsg = WSOutgoingMessage(type: "auth")
        try? await send(authMsg)

        connectionState = .connected
        reconnectAttempts = 0
        startReceiving()
        startPingLoop()
    }

    private func startReceiving() {
        receiveTask?.cancel()
        receiveTask = Task {
            guard let task = webSocketTask else { return }
            while !Task.isCancelled {
                do {
                    let result = try await task.receive()
                    switch result {
                    case .string(let text):
                        if let data = text.data(using: .utf8),
                           let msg = try? JSONDecoder().decode(WSMessage.self, from: data) {
                            messageSubject.send(msg)
                        }
                    case .data(let data):
                        if let msg = try? JSONDecoder().decode(WSMessage.self, from: data) {
                            messageSubject.send(msg)
                        }
                    @unknown default:
                        break
                    }
                } catch {
                    if !Task.isCancelled {
                        handleDisconnect(error: error)
                    }
                    return
                }
            }
        }
    }

    private func handleDisconnect(error: Error) {
        connectionState = .error(error.localizedDescription)
        lastError = error.localizedDescription
        scheduleReconnect()
    }

    private func scheduleReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            connectionState = .error("Max reconnect attempts reached. Please reconnect manually.")
            return
        }
        let delay = min(pow(2.0, Double(reconnectAttempts)), 60.0)
        reconnectAttempts += 1
        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await openConnection()
        }
    }

    private func startPingLoop() {
        pingTask?.cancel()
        pingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
                guard !Task.isCancelled else { return }
                try? await send(WSOutgoingMessage(type: "ping"))
            }
        }
    }

    private func stopAll() {
        receiveTask?.cancel()
        receiveTask = nil
        pingTask?.cancel()
        pingTask = nil
        reconnectTask?.cancel()
        reconnectTask = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }

    // MARK: - URL Construction (internal for testing)

    func makeWebSocketURL(from urlString: String, token: String) -> URL? {
        guard var components = URLComponents(string: urlString) else { return nil }

        switch components.scheme {
        case "http":  components.scheme = "ws"
        case "https": components.scheme = "wss"
        case "ws", "wss": break
        default: components.scheme = "ws"
        }

        components.path = "/"

        var queryItems = components.queryItems ?? []
        queryItems.removeAll { $0.name == "token" }
        queryItems.append(URLQueryItem(name: "token", value: token))
        components.queryItems = queryItems

        return components.url
    }
}
