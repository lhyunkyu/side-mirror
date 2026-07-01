import SwiftUI
import AVFoundation

struct WarningOverlayView: View {
    let direction: IntruderDirection
    let session: AVCaptureSession
    @State private var pulse = false
    @State private var slideOffset: CGFloat = 300

    var body: some View {
        VStack {
            Spacer()
            HStack {
                if direction == .left || direction == .center {
                    warningBadge()
                        .padding(.leading, 48)
                }
                Spacer()
                if direction == .right || direction == .center {
                    warningBadge()
                        .padding(.trailing, 48)
                }
            }
            .padding(.bottom, 60)
        }
        .offset(y: slideOffset)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                slideOffset = 0
            }
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private func warningBadge() -> some View {
        ZStack(alignment: .top) {
            // 실시간 카메라 피드
            CameraPreviewView(session: session)

            // warning 아이콘 오버레이 (좌상단)
            Image("warning_icon", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)
                .padding(12)
        }
        .frame(width: 160, height: 160)
        .background(Color.white)
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 4)
        .scaleEffect(pulse ? 1.06 : 1.0)
    }
}
