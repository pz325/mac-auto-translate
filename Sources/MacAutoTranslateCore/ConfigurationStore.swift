import Foundation

/// App-owned JSON persistence shared across all executable adapters.
public struct ConfigurationStore: Sendable {
    public let directoryURL: URL

    public init(directoryURL: URL? = nil) {
        if let directoryURL {
            self.directoryURL = directoryURL
        } else if let override = ProcessInfo.processInfo.environment["MAC_AUTO_TRANSLATE_HOME"], !override.isEmpty {
            self.directoryURL = URL(fileURLWithPath: override, isDirectory: true)
        } else {
            let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.directoryURL = applicationSupport.appendingPathComponent("MacAutoTranslate", isDirectory: true)
        }
    }

    public var configurationURL: URL { directoryURL.appendingPathComponent("config.json") }
    public var credentialsURL: URL { directoryURL.appendingPathComponent("credentials.json") }
    public var sessionURL: URL { directoryURL.appendingPathComponent("session.json") }

    public func loadConfiguration() -> LLMConfiguration {
        load(LLMConfiguration.self, from: configurationURL) ?? LLMConfiguration()
    }

    public func loadCredentials() -> Credentials {
        load(Credentials.self, from: credentialsURL) ?? Credentials()
    }

    public func loadSession() -> TranslationSession {
        load(TranslationSession.self, from: sessionURL) ?? TranslationSession()
    }

    public func save(configuration: LLMConfiguration, credentials: Credentials) throws {
        try prepareDirectory()
        try save(configuration, to: configurationURL, permissions: 0o600)
        try save(credentials, to: credentialsURL, permissions: 0o600)
    }

    public func save(session: TranslationSession) throws {
        try prepareDirectory()
        try save(session, to: sessionURL, permissions: 0o600)
    }

    public func summary() -> ConfigurationSummary {
        let config = loadConfiguration()
        let credentials = loadCredentials()
        return ConfigurationSummary(
            provider: config.provider,
            baseURL: config.baseURL,
            model: config.model,
            timeoutMilliseconds: config.timeoutMilliseconds,
            servicePort: config.servicePort,
            hasAPIKey: !credentials.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        )
    }

    private func load<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func prepareDirectory() throws {
        do {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directoryURL.path)
        } catch {
            throw MacAutoTranslateError.persistence(error.localizedDescription)
        }
    }

    private func save<T: Encodable>(_ value: T, to url: URL, permissions: Int) throws {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: url.path)
        } catch {
            throw MacAutoTranslateError.persistence(error.localizedDescription)
        }
    }
}
