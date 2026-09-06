import XCTest
@testable import MacAutoTranslateCore

final class EndpointResolverTests: XCTestCase {
    func testOpenAIEndpointVariants() throws {
        XCTAssertEqual(
            try EndpointResolver.endpoint(for: .openAI, baseURL: "https://api.openai.com").absoluteString,
            "https://api.openai.com/v1/responses"
        )
        XCTAssertEqual(
            try EndpointResolver.endpoint(for: .openAI, baseURL: "https://example.com/v1/").absoluteString,
            "https://example.com/v1/responses"
        )
    }

    func testKimiAnthropicEndpoint() throws {
        XCTAssertEqual(
            try EndpointResolver.endpoint(for: .anthropic, baseURL: "https://api.kimi.com/coding/").absoluteString,
            "https://api.kimi.com/coding/v1/messages"
        )
    }

    func testRejectsNonHTTPURL() {
        XCTAssertThrowsError(try EndpointResolver.endpoint(for: .openAI, baseURL: "file:///tmp/key"))
    }
}
