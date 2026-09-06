import Foundation
import XCTest
@testable import MacAutoTranslateCore

final class ConfigurationStoreTests: XCTestCase {
    func testSeparatesSecretsAndRestoresSession() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacAutoTranslateTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = ConfigurationStore(directoryURL: directory)
        var config = LLMConfiguration()
        config.model = "test-model"
        try store.save(configuration: config, credentials: Credentials(apiKey: "test-secret-value"))
        try store.save(session: TranslationSession(input: "hello", result: "你好"))

        XCTAssertEqual(store.loadConfiguration().model, "test-model")
        XCTAssertEqual(store.loadCredentials().apiKey, "test-secret-value")
        XCTAssertEqual(store.loadSession().result, "你好")

        let ordinaryConfig = try String(contentsOf: store.configurationURL, encoding: .utf8)
        XCTAssertFalse(ordinaryConfig.contains("test-secret-value"))
        XCTAssertEqual(store.summary().hasAPIKey, true)

        let attributes = try FileManager.default.attributesOfItem(atPath: store.credentialsURL.path)
        XCTAssertEqual((attributes[.posixPermissions] as? NSNumber)?.intValue, 0o600)
    }
}
