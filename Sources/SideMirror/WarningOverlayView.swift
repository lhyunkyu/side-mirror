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
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                slideOffset = 0
            }
        }
    }

    private func warningBadge(iconAlignment: Alignment) -> some View {
        ZStack(alignment: iconAlignment) {
            CameraPreviewView(session: session)

            Image("warning_icon", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .padding(10)
        }
        .frame(width: 160, height: 160)
        .background(Color.white)
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 4)
    }
}
