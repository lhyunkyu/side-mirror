import SwiftUI
import AVFoundation

struct WarningOverlayView: View {
    let direction: IntruderDirection
    let session: AVCaptureSession
    @State private var slideOffset: CGFloat = 300

    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom) {
                if direction == .left || direction == .center {
                    warningBadge(iconAlignment: .topLeading)
                        .padding(.leading, 48)
                }
                Spacer()
                if direction == .right || direction == .center {
                    warningBadge(iconAlignment: .topTrailing)
                        .padding(.trailing, 48)
                }
            }
            .padding(.bottom, 140)
        }
        .offset(y: slideOffset)
    }

    private func warningBadge(iconAlignment: Alignment) -> some View {
        ZStack(alignment: iconAlignment) {
            CameraPreviewView(session: session) {
                // 카메라 렌더링 준비 완료 → 그때 슬라이드 업
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    slideOffset = 0
                }
            }

            if let url = Bundle.module.url(forResource: "warning_icon", withExtension: "png"),
               let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .padding(10)
            }
        }
        .frame(width: 160, height: 160)
        .background(Color.white)
        .clipShape(Circle())
        .mask(
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .white, location: 0.0),
                    .init(color: .white, location: 0.72),
                    .init(color: .clear, location: 1.0)
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 80
            )
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 6)
    }
}
