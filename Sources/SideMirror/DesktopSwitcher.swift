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
        } else {
            activate(bundleID: "com.apple.mail")
        }
    }

    private func activate(bundleID: String) {
        NSWorkspace.shared.launchApplication(
            withBundleIdentifier: bundleID,
            options: [],
            additionalEventParamDescriptor: nil,
            launchIdentifier: nil
        )
    }

    private func isRunning(bundleID: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == bundleID
        }
    }

    private func showDesktop() {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: showDesktopKeyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: showDesktopKeyCode, keyDown: false)
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
