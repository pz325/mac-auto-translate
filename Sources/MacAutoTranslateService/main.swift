import Foundation
import MacAutoTranslateCore

private func argument(named name: String) -> String? {
    guard let index = CommandLine.arguments.firstIndex(of: name), CommandLine.arguments.indices.contains(index + 1) else {
        return nil
    }
    return CommandLine.arguments[index + 1]
}

if CommandLine.arguments.contains("--help") || CommandLine.arguments.contains("-h") {
    print("""
    Usage: mac-auto-translate-service [--port 8765]

    Starts the MacAutoTranslate HTTP API on 127.0.0.1 only.
    Configuration is loaded from the app's Application Support directory.
    """)
    exit(0)
}

let store = ConfigurationStore()
let configuredPort = store.loadConfiguration().servicePort
let port: UInt16
if let raw = argument(named: "--port") {
    guard let parsed = UInt16(raw) else {
        FileHandle.standardError.write(Data("Invalid --port value: \(raw)\n".utf8))
        exit(2)
    }
    port = parsed
} else {
    port = configuredPort
}

do {
    let server = TranslationHTTPServer(port: port, store: store)
    try server.start()
    FileHandle.standardError.write(Data("MacAutoTranslate API listening on http://127.0.0.1:\(port)\n".utf8))
    withExtendedLifetime(server) {
        RunLoop.current.run()
    }
} catch {
    FileHandle.standardError.write(Data("Unable to start service: \(error.localizedDescription)\n".utf8))
    exit(1)
}
