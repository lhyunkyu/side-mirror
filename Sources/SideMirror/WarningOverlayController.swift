import Cocoa
import SwiftUI

final class WarningOverlayController {
    private var window: NSWindow?
    private var hostingView: NSHostingView<WarningOverlayView>?
    private var isFadingOut = false

    func showImmediately(direction: IntruderDirection) {
        isFadingOut = false

        if let window, let hostingView {
            window.alphaValue = 1
            hostingView.rootView = WarningOverlayView(direction: direction)
            return
        }

        guard let screen = NSScreen.main else { return }
        let view = NSHostingView(rootView: WarningOverlayView(direction: direction))
        let panel = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .screenSaver
        panel.ignoresMouseEvents = true
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.contentView = view
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        window = panel
        hostingView = view
    }

    func fadeOut() {
        guard let window, !isFadingOut else { return }
        isFadingOut = true
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            guard let self, self.isFadingOut else { return }
            window.orderOut(nil)
            self.window = nil
            self.hostingView = nil
            self.isFadingOut = false
        })
    }
}
