import Cocoa
import SwiftUI
import AVFoundation

final class WarningOverlayController {
    private let session: AVCaptureSession
    private var window: NSWindow?
    private var hostingView: NSHostingView<WarningOverlayView>?
    private var isFadingOut = false
    private var lockedDirection: IntruderDirection?

    init(session: AVCaptureSession) {
        self.session = session
    }

    func showImmediately(direction: IntruderDirection) {
        isFadingOut = false

        if lockedDirection == nil { lockedDirection = direction }
        let displayDirection = lockedDirection!

        if let window {
            // 진행 중인 fadeOut 애니메이션 즉시 취소 후 복원
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0
                window.animator().alphaValue = 1
            }
            window.orderFrontRegardless()
            return
        }

        guard let screen = NSScreen.main else { return }
        let view = NSHostingView(rootView: WarningOverlayView(direction: displayDirection, session: session))
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
        lockedDirection = nil
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
