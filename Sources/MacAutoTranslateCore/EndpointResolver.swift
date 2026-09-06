import Foundation

public enum EndpointResolver {
    public static func endpoint(for provider: LLMProvider, baseURL: String) throws -> URL {
        let trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed),
              let scheme = components.scheme,
              ["http", "https"].contains(scheme.lowercased()),
              components.host != nil else {
            throw MacAutoTranslateError.invalidBaseURL(baseURL)
        }

        var path = components.path
        while path.count > 1 && path.hasSuffix("/") { path.removeLast() }

        let endpointSuffix: String
        switch provider {
        case .openAI:
            endpointSuffix = path.hasSuffix("/responses") ? "" : (path.hasSuffix("/v1") ? "/responses" : "/v1/responses")
        case .anthropic:
            endpointSuffix = path.hasSuffix("/messages") ? "" : (path.hasSuffix("/v1") ? "/messages" : "/v1/messages")
        }
        components.path = path + endpointSuffix

        guard let url = components.url else {
            throw MacAutoTranslateError.invalidBaseURL(baseURL)
        }
        return url
    }
}
