import Foundation

/// REST client for the OpenClaw gateway API.
final class OpenClawClient {
    private var gatewayURL: URL
    private var authToken: String

    init(gatewayURL: URL = URL(string: Constants.defaultGatewayURL)!,
         authToken: String = "") {
        self.gatewayURL = gatewayURL
        self.authToken = authToken
    }

    func configure(gatewayURL: URL, authToken: String) {
        self.gatewayURL = gatewayURL
        self.authToken = authToken
    }

    /// Send a chat completion request and return the assistant reply.
    func sendChatCompletion(messages: [Message]) async throws -> Message {
        // TODO: Implement URLSession-based POST to /v1/chat/completions
        throw URLError(.unsupportedURL)
    }

    /// Check connectivity to the gateway.
    func ping() async throws -> Bool {
        // TODO: GET /health or equivalent
        return false
    }
}
