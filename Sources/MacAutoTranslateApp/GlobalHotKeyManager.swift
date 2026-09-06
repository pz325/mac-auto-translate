import Carbon
import Foundation

@MainActor
final class GlobalHotKeyManager {
    private var hotKey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let onPressed: @MainActor () -> Void

    init(onPressed: @escaping @MainActor () -> Void) {
        self.onPressed = onPressed
    }

    func register() throws {
        unregister()
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in manager.onPressed() }
                return noErr
            },
            1,
            &eventType,
            pointer,
            &eventHandler
        )
        guard handlerStatus == noErr else {
            throw MacHotKeyError.registrationFailed(handlerStatus)
        }

        let identifier = EventHotKeyID(signature: OSType(0x4D_41_54_36), id: 1) // MAT6
        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_6),
            UInt32(cmdKey | shiftKey),
            identifier,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )
        guard registerStatus == noErr else {
            unregister()
            throw MacHotKeyError.registrationFailed(registerStatus)
        }
    }

    func unregister() {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
        hotKey = nil
        eventHandler = nil
    }

    deinit {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }
}

private enum MacHotKeyError: LocalizedError {
    case registrationFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case let .registrationFailed(status):
            "无法注册 ⇧⌘6 全局快捷键（状态码 \(status)）。它可能已被其他 app 占用。"
        }
    }
}
