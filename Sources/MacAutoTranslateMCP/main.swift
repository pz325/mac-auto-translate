import Foundation
import MacAutoTranslateCore

private struct JSONRPCRequest: Decodable {
    let jsonrpc: String
    let id: JSONValue?
    let method: String
    let params: JSONValue?
}

private enum JSONValue: Codable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode([String: JSONValue].self) { self = .object(value) }
        else { self = .array(try container.decode([JSONValue].self)) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value): try container.encode(value)
        case let .number(value): try container.encode(value)
        case let .bool(value): try container.encode(value)
        case let .object(value): try container.encode(value)
        case let .array(value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    var object: [String: JSONValue]? {
        if case let .object(value) = self { value } else { nil }
    }

    var string: String? {
        if case let .string(value) = self { value } else { nil }
    }
}

private let store = ConfigurationStore()
private let client = LLMClient()
private let encoder: JSONEncoder = {
    let value = JSONEncoder()
    value.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return value
}()

private func write(_ value: JSONValue) {
    guard let data = try? encoder.encode(value) else { return }
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data([0x0A]))
}

private func response(id: JSONValue, result: JSONValue) -> JSONValue {
    .object(["jsonrpc": .string("2.0"), "id": id, "result": result])
}

private func failure(id: JSONValue, code: Double, message: String) -> JSONValue {
    .object([
        "jsonrpc": .string("2.0"),
        "id": id,
        "error": .object(["code": .number(code), "message": .string(message)]),
    ])
}

private func handle(_ request: JSONRPCRequest) async {
    guard let id = request.id else { return }

    switch request.method {
    case "initialize":
        let requestedVersion = request.params?.object?["protocolVersion"]?.string ?? "2025-06-18"
        write(response(id: id, result: .object([
            "protocolVersion": .string(requestedVersion),
            "capabilities": .object(["tools": .object(["listChanged": .bool(false)])]),
            "serverInfo": .object(["name": .string("mac-auto-translate"), "version": .string("0.1.0")]),
        ])))
    case "ping":
        write(response(id: id, result: .object([:])))
    case "tools/list":
        write(response(id: id, result: .object([
            "tools": .array([
                .object([
                    "name": .string("translate"),
                    "description": .string("Translate text using the configured MacAutoTranslate LLM and prompt."),
                    "inputSchema": .object([
                        "type": .string("object"),
                        "properties": .object([
                            "text": .object(["type": .string("string"), "description": .string("Text to translate")]),
                            "sourceLanguage": .object(["type": .string("string"), "description": .string("Optional natural-language source language")]),
                            "targetLanguage": .object(["type": .string("string"), "description": .string("Optional natural-language target language")]),
                        ]),
                        "required": .array([.string("text")]),
                    ]),
                ])
            ]),
        ])))
    case "tools/call":
        guard let params = request.params?.object,
              params["name"]?.string == "translate",
              let arguments = params["arguments"]?.object,
              let text = arguments["text"]?.string else {
            write(failure(id: id, code: -32602, message: "Invalid translate arguments"))
            return
        }
        do {
            let result = try await client.translate(
                TranslationRequest(
                    text: text,
                    sourceLanguage: arguments["sourceLanguage"]?.string,
                    targetLanguage: arguments["targetLanguage"]?.string
                ),
                configuration: store.loadConfiguration(),
                credentials: store.loadCredentials()
            )
            write(response(id: id, result: .object([
                "content": .array([.object(["type": .string("text"), "text": .string(result.translatedText)])]),
                "structuredContent": .object([
                    "translatedText": .string(result.translatedText),
                    "sourceLanguage": .string(result.sourceLanguage),
                    "targetLanguage": .string(result.targetLanguage),
                    "provider": .string(result.provider.rawValue),
                    "model": .string(result.model),
                ]),
                "isError": .bool(false),
            ])))
        } catch {
            write(response(id: id, result: .object([
                "content": .array([.object(["type": .string("text"), "text": .string(error.localizedDescription)])]),
                "isError": .bool(true),
            ])))
        }
    default:
        write(failure(id: id, code: -32601, message: "Method not found: \(request.method)"))
    }
}

while let line = readLine(strippingNewline: true) {
    guard let data = line.data(using: .utf8) else { continue }
    do {
        let request = try JSONDecoder().decode(JSONRPCRequest.self, from: data)
        await handle(request)
    } catch {
        write(failure(id: .null, code: -32700, message: "Parse error"))
    }
}
