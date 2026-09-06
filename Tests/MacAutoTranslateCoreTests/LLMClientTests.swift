import Foundation
import XCTest
@testable import MacAutoTranslateCore

final class LLMClientTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.handler = nil
        super.tearDown()
    }

    func testOpenAIRequestAndResponse() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.openai.com/v1/responses")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
            let body = try request.bodyData()
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
            XCTAssertEqual(object["input"] as? String, "Hello")
            XCTAssertEqual(object["store"] as? Bool, false)
            XCTAssertTrue((object["instructions"] as? String)?.contains("英文") == true)
            let response = """
            {"output":[{"type":"reasoning","summary":[]},{"type":"message","content":[{"type":"output_text","text":"你好"}]}]}
            """.data(using: .utf8)!
            return (200, response)
        }

        var config = LLMConfiguration(provider: .openAI, baseURL: "https://api.openai.com", model: "test")
        config.prompt = "Translate [Source] to [Target]"
        let result = try await makeClient().translate(
            TranslationRequest(text: "Hello", sourceLanguage: "英文", targetLanguage: "中文"),
            configuration: config,
            credentials: Credentials(apiKey: "test-key")
        )
        XCTAssertEqual(result.translatedText, "你好")
    }

    func testAnthropicRequestAndResponse() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.kimi.com/coding/v1/messages")
            XCTAssertEqual(request.value(forHTTPHeaderField: "x-api-key"), "kimi-test-key")
            XCTAssertEqual(request.value(forHTTPHeaderField: "anthropic-version"), "2023-06-01")
            let response = """
            {"content":[{"type":"thinking","thinking":"summary","signature":"opaque"},{"type":"text","text":"Hello, world"}]}
            """.data(using: .utf8)!
            return (200, response)
        }

        let result = try await makeClient().translate(
            TranslationRequest(text: "你好，世界"),
            configuration: LLMConfiguration(),
            credentials: Credentials(apiKey: "kimi-test-key")
        )
        XCTAssertEqual(result.translatedText, "Hello, world")
        XCTAssertEqual(result.sourceLanguage, "中文")
        XCTAssertEqual(result.targetLanguage, "英文")
    }

    func testProviderErrorRedactsKey() async {
        MockURLProtocol.handler = { _ in
            (401, Data("{\"error\":{\"message\":\"bad key super-secret\"}}".utf8))
        }
        do {
            _ = try await makeClient().translate(
                TranslationRequest(text: "hello"),
                configuration: LLMConfiguration(provider: .openAI, baseURL: "https://api.openai.com", model: "test"),
                credentials: Credentials(apiKey: "super-secret")
            )
            XCTFail("Expected provider error")
        } catch {
            XCTAssertFalse(error.localizedDescription.contains("super-secret"))
            XCTAssertTrue(error.localizedDescription.contains("[REDACTED]"))
        }
    }

    func testMalformedSuccessResponseReturnsActionableError() async {
        MockURLProtocol.handler = { _ in (200, Data("{\"unexpected\":true}".utf8)) }
        do {
            _ = try await makeClient().translate(
                TranslationRequest(text: "hello"),
                configuration: LLMConfiguration(provider: .openAI, baseURL: "https://api.openai.com", model: "test"),
                credentials: Credentials(apiKey: "test-key")
            )
            XCTFail("Expected invalid response error")
        } catch {
            XCTAssertEqual(error as? MacAutoTranslateError, .invalidResponse)
            XCTAssertEqual(error.localizedDescription, "LLM 返回了无法解析的响应。")
        }
    }

    private func makeClient() -> LLMClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return LLMClient(session: URLSession(configuration: configuration))
    }
}

private extension URLRequest {
    func bodyData() throws -> Data {
        if let httpBody { return httpBody }
        let stream = try XCTUnwrap(httpBodyStream)
        stream.open()
        defer { stream.close() }

        var result = Data()
        var buffer = [UInt8](repeating: 0, count: 4_096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count < 0 { throw try XCTUnwrap(stream.streamError) }
            if count == 0 { break }
            result.append(buffer, count: count)
        }
        return result
    }
}

private final class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            let handler = try XCTUnwrap(Self.handler)
            let (status, data) = try handler(request)
            let response = try XCTUnwrap(HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            ))
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
