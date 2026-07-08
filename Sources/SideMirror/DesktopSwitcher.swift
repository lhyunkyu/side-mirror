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
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { [weak self] _, _ in
            // 앱 활성화 후 AX로 창을 최상단으로 올림
            DispatchQueue.main.async {
                self?.raiseWindows(bundleID: bundleID)
            }
        }
    }

    private func raiseWindows(bundleID: String) {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }) else { return }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var windowsRef: CFTypeRef?
        AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)
        guard let windows = windowsRef as? [AXUIElement] else { return }
        for window in windows {
            AXUIElementSetAttributeValue(window, kAXMainAttribute as CFString, true as CFTypeRef)
            AXUIElementSetAttributeValue(window, kAXFocusedAttribute as CFString, true as CFTypeRef)
        }
    }

    private func isFullscreen(bundleID: String) -> Bool {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }) else { return false }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var windowsRef: CFTypeRef?
        AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, & windowsRef)
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
