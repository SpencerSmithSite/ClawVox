import Foundation

/// Streaming WebSocket client for real-time token delivery from OpenClaw.
final class WebSocketClient {
    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession = .shared

    var onMessage: ((String) -> Void)?
    var onConnectionChange: ((ConnectionState) -> Void)?

    func connect(to url: URL, authToken: String) {
        // TODO: Create URLSessionWebSocketTask, attach auth header, receive loop
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        onConnectionChange?(.disconnected)
    }

    func send(_ text: String) async throws {
        // TODO: webSocketTask?.send(.string(text))
        throw URLError(.unsupportedURL)
    }
}
