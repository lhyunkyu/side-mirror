import ApplicationServices
import Cocoa

final class DesktopSwitcher {
    private let showDesktopKeyCode: CGKeyCode = 103 // F11, default "Show Desktop" shortcut

    func requestAccessibilityPermissionIfNeeded() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func showDesktop() {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: showDesktopKeyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: showDesktopKeyCode, keyDown: false)
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
