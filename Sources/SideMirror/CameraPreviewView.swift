import SwiftUI
import AVFoundation

struct CameraPreviewView: NSViewRepresentable {
    let session: AVCaptureSession
    var onReady: () -> Void = {}

    func makeNSView(context: Context) -> PreviewNSView {
        let view = PreviewNSView()
        view.wantsLayer = true
        view.onFirstDisplay = onReady
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        if let connection = previewLayer.connection, connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = false
        }
        view.layer?.addSublayer(previewLayer)
        return view
    }

    func updateNSView(_ nsView: PreviewNSView, context: Context) {
        if let previewLayer = nsView.layer?.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = nsView.bounds
        }
    }
}

final class PreviewNSView: NSView {
    var onFirstDisplay: (() -> Void)?
    private var hasFired = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil, !hasFired else { return }
        // 다음 runloop에서 프리뷰 레이어가 첫 프레임을 받을 때까지 대기
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self, !self.hasFired else { return }
            self.hasFired = true
            self.onFirstDisplay?()
        }
    }
}
