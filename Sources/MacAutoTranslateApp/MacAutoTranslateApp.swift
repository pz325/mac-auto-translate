import AppKit
import MacAutoTranslateCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let state = AppState()
    private var panelController: SpotlightPanelController?
    private var hotKeyManager: GlobalHotKeyManager?
    private var httpServer: TranslationHTTPServer?

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
        MenuBarExtra("MacAutoTranslate", image: "MenuBarIconTemplate") {
            Button("打开翻译浮窗  ⇧⌘6", action: appDelegate.showTranslator)
            Divider()
            if let message = appDelegate.state.serviceMessage {
                Text(message)
            } else {
                Text("本地 API：127.0.0.1:\(appDelegate.state.store.loadConfiguration().servicePort)")
            }
            Divider()
            Button("设置…") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .keyboardShortcut(",")
            Button("退出 MacAutoTranslate") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }

        Settings {
            SettingsView(store: appDelegate.state.store)
        }
    }
}
