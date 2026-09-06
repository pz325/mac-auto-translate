import AppKit
import MacAutoTranslateCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let state = AppState()
    private var panelController: SpotlightPanelController?
    private var hotKeyManager: GlobalHotKeyManager?
    private var httpServer: TranslationHTTPServer?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let panelController = SpotlightPanelController(state: state)
        self.panelController = panelController

        let hotKey = GlobalHotKeyManager { panelController.toggle() }
        do {
            try hotKey.register()
            hotKeyManager = hotKey
        } catch {
            state.serviceMessage = error.localizedDescription
        }

        let port = state.store.loadConfiguration().servicePort
        let server = TranslationHTTPServer(port: port, store: state.store)
        do {
            try server.start()
            httpServer = server
        } catch {
            state.serviceMessage = "本地 API 未启动：\(error.localizedDescription)"
        }

        statusItemController = StatusItemController(
            statusText: { [weak self] in
                guard let self else { return "本地 API：状态未知" }
                if let message = self.state.serviceMessage {
                    return message
                }
                let port = self.state.store.loadConfiguration().servicePort
                return "本地 API：127.0.0.1:\(port)"
            },
            openTranslator: { [weak self] in self?.showTranslator() },
            openSettings: {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            },
            quit: { NSApp.terminate(nil) }
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager?.unregister()
        httpServer?.stop()
    }

    func showTranslator() { panelController?.show() }
}

@main
struct MacAutoTranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(store: appDelegate.state.store)
        }
    }
}
