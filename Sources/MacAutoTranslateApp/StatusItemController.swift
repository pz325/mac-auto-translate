import AppKit

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let statusText: () -> String
    private let openTranslator: () -> Void
    private let openSettings: () -> Void
    private let quit: () -> Void

    init(
        statusText: @escaping () -> String,
        openTranslator: @escaping () -> Void,
        openSettings: @escaping () -> Void,
        quit: @escaping () -> Void
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.statusText = statusText
        self.openTranslator = openTranslator
        self.openSettings = openSettings
        self.quit = quit
        super.init()
        configureStatusItem()
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu(menu)
    }

    private func configureStatusItem() {
        if let image = Bundle.main.image(forResource: NSImage.Name("MenuBarIcon")) {
            image.isTemplate = false
            image.size = NSSize(width: 18, height: 18)
            statusItem.button?.image = image
            statusItem.button?.imageScaling = .scaleProportionallyDown
        } else {
            let fallback = NSImage(systemSymbolName: "character.bubble", accessibilityDescription: "MacAutoTranslate")
            fallback?.isTemplate = true
            statusItem.button?.image = fallback
        }

        statusItem.button?.toolTip = "MacAutoTranslate"
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        rebuildMenu(menu)
    }

    private func rebuildMenu(_ menu: NSMenu) {
        menu.removeAllItems()

        let openItem = NSMenuItem(title: "打开翻译浮窗", action: #selector(openTranslatorFromMenu), keyEquivalent: "6")
        openItem.keyEquivalentModifierMask = [.command, .shift]
        openItem.target = self
        menu.addItem(openItem)
        menu.addItem(.separator())

        let serviceItem = NSMenuItem(title: statusText(), action: nil, keyEquivalent: "")
        serviceItem.isEnabled = false
        menu.addItem(serviceItem)
        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "设置…", action: #selector(openSettingsFromMenu), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = [.command]
        settingsItem.target = self
        menu.addItem(settingsItem)

        let quitItem = NSMenuItem(title: "退出 MacAutoTranslate", action: #selector(quitFromMenu), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = [.command]
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func openTranslatorFromMenu() {
        openTranslator()
    }

    @objc private func openSettingsFromMenu() {
        openSettings()
    }

    @objc private func quitFromMenu() {
        quit()
    }
}
