import Foundation
import Network

/// Minimal loopback-only HTTP adapter for the translation library.
public final class TranslationHTTPServer {
    public let port: UInt16

    private let store: ConfigurationStore
    private let client: LLMClient
    private let queue = DispatchQueue(label: "MacAutoTranslate.HTTPServer")
    private var listener: NWListener?

    public init(port: UInt16, store: ConfigurationStore = ConfigurationStore(), client: LLMClient = LLMClient()) {
        self.port = port
        self.store = store
        self.client = client
    }

    public func start() throws {
        guard listener == nil else { return }
        guard let networkPort = NWEndpoint.Port(rawValue: port) else {
            throw MacAutoTranslateError.service("端口无效：\(port)")
        }

        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: networkPort)
        let listener = try NWListener(using: parameters)
        listener.stateUpdateHandler = { state in
            if case let .failed(error) = state {
                FileHandle.standardError.write(Data("MacAutoTranslate service failed: \(error)\n".utf8))
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.accept(connection)
        }
        listener.start(queue: queue)
        self.listener = listener
    }

    public func stop() {
        listener?.cancel()
        listener = nil
    }

    private func accept(_ connection: NWConnection) {
        connection.start(queue: queue)
        receive(on: connection, accumulated: Data())
    }

    private func receive(on connection: NWConnection, accumulated: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, isComplete, error in
            guard let self else {
                connection.cancel()
                return
            }
            if error != nil {
                connection.cancel()
                return
            }

            var buffer = accumulated
            if let data { buffer.append(data) }
            guard buffer.count <= 2_097_152 else {
                self.send(.json(status: 413, object: ErrorPayload(error: "Request body is too large")), on: connection)
                return
            }

            if let request = HTTPRequest.parse(buffer) {
                Task {
                    let response = await self.route(request)
                    self.send(response, on: connection)
                }
            } else if isComplete {
                self.send(.json(status: 400, object: ErrorPayload(error: "Malformed HTTP request")), on: connection)
            } else {
                self.receive(on: connection, accumulated: buffer)
            }
        }
    }

    private func route(_ request: HTTPRequest) async -> HTTPResponse {
        if request.method == "OPTIONS" {
            return HTTPResponse(status: 204, body: Data())
        }

        switch (request.method, request.path) {
        case ("GET", "/health"):
            return .json(status: 200, object: HealthPayload(status: "ok", service: "mac-auto-translate", version: "0.1.0"))
        case ("GET", "/v1/config"):
            return .json(status: 200, object: store.summary())
        case ("POST", "/v1/translate"):
            do {
                let translationRequest = try JSONDecoder().decode(TranslationRequest.self, from: request.body)
                let result = try await client.translate(
                    translationRequest,
                    configuration: store.loadConfiguration(),
                    credentials: store.loadCredentials()
                )
                return .json(status: 200, object: result)
            } catch let error as MacAutoTranslateError {
                return .json(status: Self.status(for: error), object: ErrorPayload(error: error.localizedDescription))
            } catch {
                return .json(status: 500, object: ErrorPayload(error: error.localizedDescription))
            }
        default:
            return .json(status: 404, object: ErrorPayload(error: "Route not found"))
        }
    }

    private func send(_ response: HTTPResponse, on connection: NWConnection) {
        let reason = Self.reasonPhrase(for: response.status)
        let header = """
        HTTP/1.1 \(response.status) \(reason)\r
        Content-Type: application/json; charset=utf-8\r
        Content-Length: \(response.body.count)\r
        Access-Control-Allow-Origin: http://localhost\r
        Access-Control-Allow-Headers: Content-Type\r
        Access-Control-Allow-Methods: GET, POST, OPTIONS\r
        Connection: close\r
        \r

        """
        var data = Data(header.utf8)
        data.append(response.body)
        connection.send(content: data, completion: .contentProcessed { _ in connection.cancel() })
    }

    private static func status(for error: MacAutoTranslateError) -> Int {
        switch error {
        case .emptyInput, .missingAPIKey, .invalidBaseURL: 400
        case let .provider(statusCode, _): statusCode
        default: 500
        }
    }

    private static func reasonPhrase(for status: Int) -> String {
        switch status {
        case 200: "OK"
        case 204: "No Content"
        case 400: "Bad Request"
        case 401: "Unauthorized"
        case 403: "Forbidden"
        case 404: "Not Found"
        case 413: "Content Too Large"
        case 429: "Too Many Requests"
        case 500: "Internal Server Error"
        case 502: "Bad Gateway"
        case 503: "Service Unavailable"
        default: "HTTP Response"
        }
    }
}

private struct HTTPRequest {
    let method: String
    let path: String
    let body: Data

    static func parse(_ data: Data) -> HTTPRequest? {
        let separator = Data("\r\n\r\n".utf8)
        guard let headerRange = data.range(of: separator),
              let headerText = String(data: data[..<headerRange.lowerBound], encoding: .utf8) else {
            return nil
        }

        let lines = headerText.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return nil }
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else { return nil }

        let contentLength = lines.dropFirst().compactMap { line -> Int? in
            let pair = line.split(separator: ":", maxSplits: 1)
            guard pair.count == 2, pair[0].trimmingCharacters(in: .whitespaces).lowercased() == "content-length" else { return nil }
            return Int(pair[1].trimmingCharacters(in: .whitespaces))
        }.first ?? 0

        let bodyStart = headerRange.upperBound
        guard data.count >= bodyStart + contentLength else { return nil }
        let body = data.subdata(in: bodyStart..<(bodyStart + contentLength))
        let rawPath = String(parts[1])
        let path = rawPath.split(separator: "?", maxSplits: 1).first.map(String.init) ?? rawPath
        return HTTPRequest(method: String(parts[0]).uppercased(), path: path, body: body)
    }
}

private struct HTTPResponse {
    let status: Int
    let body: Data

    static func json<T: Encodable>(status: Int, object: T) -> HTTPResponse {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let body = (try? encoder.encode(object)) ?? Data("{\"error\":\"Encoding failed\"}".utf8)
        return HTTPResponse(status: status, body: body)
    }
}

private struct HealthPayload: Encodable {
    let status: String
    let service: String
    let version: String
}

private struct ErrorPayload: Encodable {
    let error: String
}
