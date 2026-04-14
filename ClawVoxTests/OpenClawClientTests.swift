import XCTest
@testable import ClawVox

@MainActor
final class OpenClawClientTests: XCTestCase {

    // MARK: - Helpers

    private func makeClient(gatewayURL: String = "http://localhost:18789",
                            authToken: String = "testtoken") -> OpenClawClient {
        let settings = AppSettings(gatewayURL: gatewayURL, authToken: authToken)
        return OpenClawClient(settings: settings)
    }

    // MARK: - Tests

    func testParseSSEToken_validChunk() {
        let client = makeClient()
        let json = """
        {"id":"chatcmpl-1","object":"chat.completion.chunk","choices":[{"delta":{"content":"Hello"},"finish_reason":null}]}
        """
        let result = client.parseSSEToken(json)
        XCTAssertEqual(result, "Hello")
    }

    func testParseSSEToken_roleOnlyChunk() {
        let client = makeClient()
        // Role-only chunks have no "content" key in delta
        let json = """
        {"id":"chatcmpl-1","object":"chat.completion.chunk","choices":[{"delta":{"role":"assistant"},"finish_reason":null}]}
        """
        let result = client.parseSSEToken(json)
        XCTAssertNil(result)
    }

    func testBuildRequest_setsAuthHeader() throws {
        let client = makeClient(authToken: "testtoken")
        let messages = [Message(role: .user, content: "hi")]
        let request = try client.buildRequest(messages: messages, stream: false)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer testtoken")
    }
}
