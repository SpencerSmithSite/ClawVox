import Foundation

// MARK: - Error type

enum OpenClawError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The gateway URL is not valid."
        case .invalidResponse: return "Received an unexpected response from the gateway."
        case .httpError(let code): return "Gateway returned HTTP \(code)."
        case .decodingError(let msg): return "Failed to parse response: \(msg)"
        case .cancelled: return "Request was cancelled."
        }
    }
}

// MARK: - Request/Response Codable types

private struct ChatCompletionRequest: Encodable {
    struct ChatMessage: Encodable {
        let role: String
        let content: String
    }
    let model: String
    let messages: [ChatMessage]
    let stream: Bool
}

private struct SSEChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let content: String?
        }
        let delta: Delta
        let finishReason: String?
        enum CodingKeys: String, CodingKey {
            case delta
            case finishReason = "finish_reason"
        }
    }
    let choices: [Choice]
}

private struct NonStreamingCompletion: Decodable {
    struct Choice: Decodable {
        struct ChatMessage: Decodable {
            let role: String
            let content: String
        }
        let message: ChatMessage
    }
    let choices: [Choice]
}

// MARK: - Client

@MainActor
final class OpenClawClient: ObservableObject {

    // MARK: - Public state
    @Published var connectionState: ConnectionState = .disconnected

    // MARK: - Private
    private var settings: AppSettings
    private var streamTask: Task<Void, Never>?

    init(settings: AppSettings) {
        self.settings = settings
    }

    func update(settings: AppSettings) {
        self.settings = settings
    }

    // MARK: - Streaming send (primary path)

    func streamChat(messages: [Message]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let request = try self.buildRequest(messages: messages, stream: true)
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw OpenClawError.invalidResponse
                    }
                    guard (200...299).contains(httpResponse.statusCode) else {
                        throw OpenClawError.httpError(httpResponse.statusCode)
                    }
                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        if line.hasPrefix("data: ") {
                            let data = String(line.dropFirst(6))
                            if data == "[DONE]" { break }
                            if let token = self.parseSSEToken(data) {
                                continuation.yield(token)
                            }
                        }
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish(throwing: OpenClawError.cancelled)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Non-streaming send (fallback / testing)

    func sendChat(messages: [Message]) async throws -> String {
        let request = try buildRequest(messages: messages, stream: false)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenClawError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw OpenClawError.httpError(httpResponse.statusCode)
        }
        do {
            let completion = try JSONDecoder().decode(NonStreamingCompletion.self, from: data)
            guard let content = completion.choices.first?.message.content else {
                throw OpenClawError.decodingError("No content in response choices")
            }
            return content
        } catch let err as OpenClawError {
            throw err
        } catch {
            throw OpenClawError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - Connection health check

    func checkConnection() async -> ConnectionState {
        // 1. Try GET /health
        if let healthURL = URL(string: settings.gatewayURL + "/health") {
            var healthRequest = URLRequest(url: healthURL)
            healthRequest.httpMethod = "GET"
            healthRequest.setValue("Bearer \(settings.authToken)", forHTTPHeaderField: "Authorization")
            healthRequest.timeoutInterval = 5
            if let (_, response) = try? await URLSession.shared.data(for: healthRequest),
               let http = response as? HTTPURLResponse,
               (200...299).contains(http.statusCode) {
                connectionState = .connected
                return .connected
            }
        }

        // 2. Fall back to a minimal non-streaming POST
        do {
            let pingMessage = Message(role: .user, content: "ping")
            let request = try buildRequest(messages: [pingMessage], stream: false)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                let state = ConnectionState.error("Cannot reach \(settings.gatewayURL)")
                connectionState = state
                return state
            }
            if http.statusCode == 401 || http.statusCode == 403 {
                let state = ConnectionState.error("Authentication failed — check your token")
                connectionState = state
                return state
            }
            if (200...299).contains(http.statusCode) {
                connectionState = .connected
                return .connected
            }
            let state = ConnectionState.error("Gateway returned HTTP \(http.statusCode)")
            connectionState = state
            return state
        } catch {
            let state = ConnectionState.error("Cannot reach \(settings.gatewayURL)")
            connectionState = state
            return state
        }
    }

    // MARK: - Cancel

    func cancelStream() {
        streamTask?.cancel()
        streamTask = nil
    }

    // MARK: - Helpers

    func buildRequest(messages: [Message], stream: Bool) throws -> URLRequest {
        guard let url = URL(string: settings.gatewayURL + Constants.chatCompletionsPath) else {
            throw OpenClawError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(settings.authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if stream {
            request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        }
        let body = ChatCompletionRequest(
            model: "default",
            messages: messages.map { .init(role: $0.role.rawValue, content: $0.content) },
            stream: stream
        )
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    func parseSSEToken(_ dataString: String) -> String? {
        guard let data = dataString.data(using: .utf8) else { return nil }
        guard let chunk = try? JSONDecoder().decode(SSEChunk.self, from: data) else { return nil }
        return chunk.choices.first?.delta.content
    }
}
