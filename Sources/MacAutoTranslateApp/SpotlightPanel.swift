import AppKit
import SwiftUI

final class SpotlightPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class SpotlightPanelController {
    private let panel: SpotlightPanel
    private let hostingController: NSHostingController<SpotlightView>

    init(state: AppState) {
        let panel = SpotlightPanel(
            contentRect: NSRect(x: 0, y: 0, width: SpotlightLayout.windowWidth, height: 210),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        self.panel = panel

        var controller: SpotlightPanelController?
        let rootView = SpotlightView(state: state) { height in
            controller?.resize(to: height)
        }
        hostingController = NSHostingController(rootView: rootView)
        controller = self

        panel.contentViewController = hostingController
        panel.backgroundColor = .clear
        panel.isOpaque = false
        // SwiftUI draws the single rounded shadow. A second AppKit window shadow
        // creates a larger rectangular outline with visually mismatched corners.
        panel.hasShadow = false
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.animationBehavior = .utilityWindow
        panel.isMovableByWindowBackground = true
        panel.center()
    }

    func toggle() {
        panel.isVisible ? hide() : show()
    }

    func show() {
        if let screen = NSScreen.main {
            let frame = panel.frame
            let x = screen.visibleFrame.midX - frame.width / 2
            let y = screen.visibleFrame.maxY - frame.height - 120
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        NotificationCenter.default.post(name: .focusTranslationInput, object: nil)
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func resize(to contentHeight: CGFloat) {
        // Content height comes from the native text layout. Do not cap it here:
        // a window-level cap would clip text even though both editors expanded.
        let height = max(contentHeight, 150)
        guard abs(panel.frame.height - height) > 1 else { return }
        var frame = panel.frame
        let top = frame.maxY
        frame.size.height = height
        frame.origin.y = top - height
        panel.setFrame(frame, display: true, animate: true)
    }
}

extension Notification.Name {
    static let focusTranslationInput = Notification.Name("MacAutoTranslate.focusInput")
}
