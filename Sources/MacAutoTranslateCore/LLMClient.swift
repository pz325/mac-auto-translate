import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Provider-neutral translation client.
public struct LLMClient: Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func translate(
        _ request: TranslationRequest,
        configuration: LLMConfiguration,
        credentials: Credentials
    ) async throws -> TranslationResponse {
        let text = request.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw MacAutoTranslateError.emptyInput }

        let key = credentials.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw MacAutoTranslateError.missingAPIKey }

        let automatic = LanguageDetector.automaticDirection(for: request.text)
        let source = normalized(request.sourceLanguage) ?? automatic.source
        let target = normalized(request.targetLanguage) ?? automatic.target
        let prompt = PromptRenderer.render(template: configuration.prompt, source: source, target: target)
        let url = try EndpointResolver.endpoint(for: configuration.provider, baseURL: configuration.baseURL)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = max(1, Double(configuration.timeoutMilliseconds) / 1_000)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("MacAutoTranslate/0.1", forHTTPHeaderField: "User-Agent")

        switch configuration.provider {
        case .openAI:
            urlRequest.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            urlRequest.httpBody = try JSONEncoder().encode(OpenAIRequest(
                model: configuration.model,
                instructions: prompt,
                input: request.text,
                store: false
            ))
        case .anthropic:
            urlRequest.setValue(key, forHTTPHeaderField: "x-api-key")
            urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            urlRequest.httpBody = try JSONEncoder().encode(AnthropicRequest(
                model: configuration.model,
                maxTokens: 8_192,
                system: prompt,
                messages: [.init(role: "user", content: request.text)]
            ))
        }

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw MacAutoTranslateError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw MacAutoTranslateError.provider(
                statusCode: http.statusCode,
                message: Self.providerError(from: data, redacting: key)
            )
        }

        let translated: String
        switch configuration.provider {
        case .openAI:
            translated = try Self.parseOpenAI(data)
        case .anthropic:
            translated = try Self.parseAnthropic(data)
        }

        guard !translated.isEmpty else { throw MacAutoTranslateError.noTranslatedText }
        return TranslationResponse(
            translatedText: translated,
            sourceLanguage: source,
            targetLanguage: target,
            provider: configuration.provider,
            model: configuration.model
        )
    }

    public func testConnection(configuration: LLMConfiguration, credentials: Credentials) async throws -> String {
        let response = try await translate(
            TranslationRequest(text: "Hello", sourceLanguage: "英文", targetLanguage: "中文"),
            configuration: configuration,
            credentials: credentials
        )
        return response.translatedText
    }

    static func parseOpenAI(_ data: Data) throws -> String {
        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let pieces = decoded.output
            .filter { $0.type == "message" }
            .flatMap(\.content)
            .filter { $0.type == "output_text" }
            .map(\.text)
        let result = pieces.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !result.isEmpty else { throw MacAutoTranslateError.noTranslatedText }
        return result
    }

    static func parseAnthropic(_ data: Data) throws -> String {
        let decoded = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        let result = decoded.content
            .filter { $0.type == "text" }
            .map(\.text)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !result.isEmpty else { throw MacAutoTranslateError.noTranslatedText }
        return result
    }

    private func normalized(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func providerError(from data: Data, redacting key: String) -> String {
        let fallback = String(data: data, encoding: .utf8) ?? "Unknown provider error"
        if let payload = try? JSONDecoder().decode(ProviderErrorEnvelope.self, from: data) {
            return payload.error.message.replacingOccurrences(of: key, with: "[REDACTED]")
        }
        return String(fallback.prefix(1_000)).replacingOccurrences(of: key, with: "[REDACTED]")
    }
}

private struct OpenAIRequest: Encodable {
    let model: String
    let instructions: String
    let input: String
    let store: Bool
}

private struct OpenAIResponse: Decodable {
    struct Output: Decodable {
        struct Content: Decodable {
            let type: String
            let text: String
        }
        let type: String
        let content: [Content]
    }
    let output: [Output]
}

private struct AnthropicRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }
    let model: String
    let maxTokens: Int
    let system: String
    let messages: [Message]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
    }
}

private struct AnthropicResponse: Decodable {
    struct Content: Decodable {
        let type: String
        let text: String
    }
    let content: [Content]
}

private struct ProviderErrorEnvelope: Decodable {
    struct ProviderError: Decodable { let message: String }
    let error: ProviderError
}
