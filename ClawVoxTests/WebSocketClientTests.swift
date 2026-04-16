import XCTest
@testable import ClawVox

@MainActor
final class WebSocketClientTests: XCTestCase {

    private func makeClient(gatewayURL: String = "http://localhost:18789",
                            authToken: String = "testtoken") -> WebSocketClient {
        let settings = AppSettings(gatewayURL: gatewayURL, authToken: authToken)
        return WebSocketClient(settings: settings)
    }

    func testMakeWebSocketURL_convertsHttpToWs() {
        let client = makeClient(gatewayURL: "http://localhost:18789", authToken: "abc")
        let url = client.makeWebSocketURL(from: "http://localhost:18789", token: "abc")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "ws")
        XCTAssertEqual(url?.host, "localhost")
        XCTAssertEqual(url?.port, 18789)
        XCTAssertTrue(url?.query?.contains("token=abc") ?? false)
    }

    func testMakeWebSocketURL_convertsHttpsToWss() {
        let client = makeClient()
        let url = client.makeWebSocketURL(from: "https://mygw.tailscale.net:18789", token: "xyz")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "wss")
    }

    func testDisconnect_setsStateToDisconnected() {
        let client = makeClient()
        client.disconnect()
        XCTAssertEqual(client.connectionState, .disconnected)
    }
}
