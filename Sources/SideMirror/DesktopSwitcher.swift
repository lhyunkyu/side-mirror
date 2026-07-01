import ApplicationServices
import Cocoa

final class DesktopSwitcher {
    private let showDesktopKeyCode: CGKeyCode = 103 // F11

    func requestAccessibilityPermissionIfNeeded() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options)
    }

    // Chrome이 열려 있으면 Chrome으로 전환, 없으면 바탕화면으로
    func activateSafeScreen() {
        if isRunning(bundleID: "com.google.Chrome") {
            activate(bundleID: "com.google.Chrome")
            if !isFullscreen(bundleID: "com.google.Chrome") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.sendFullscreenShortcut()
                }
            }
        } else {
            activate(bundleID: "com.apple.mail")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.sendFullscreenShortcut()
            }
        }
    }

    private func activate(bundleID: String) {
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }) {
            app.activate(options: [.activateIgnoringOtherApps])
        } else if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            NSWorkspace.shared.openApplication(at: url, configuration: .init(), completionHandler: nil)
        }
    }

    private func isFullscreen(bundleID: String) -> Bool {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }) else { return false }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var windowsRef: CFTypeRef?
        AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)
        guard let windows = windowsRef as? [AXUIElement] else { return false }
        return windows.contains { window in
            var fsRef: CFTypeRef?
            AXUIElementCopyAttributeValue(window, "AXFullScreen" as CFString, &fsRef)
            return (fsRef as? Bool) == true
        }
    }

    private func isRunning(bundleID: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == bundleID
        }
    }

    // Ctrl+Cmd+F — 전체화면 토글
    private func sendFullscreenShortcut() {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        let keyCode: CGKeyCode = 3 // F key
        let flags: CGEventFlags = [.maskControl, .maskCommand]
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyDown?.flags = flags
        keyUp?.flags   = flags
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    private func showDesktop() {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: showDesktopKeyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: showDesktopKeyCode, keyDown: false)
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
