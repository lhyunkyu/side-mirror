import SwiftUI
import AVFoundation

struct WarningOverlayView: View {
    let direction: IntruderDirection
    let session: AVCaptureSession
    @State private var slideOffset: CGFloat = 300
    @State private var cameraOpacity: Double = 0
    @State private var iconOpacity: Double = 1

    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom) {
                if direction == .left || direction == .center {
                    warningBadge(iconAlignment: .topLeading, iconEdgePadding: .leading)
                        .padding(.leading, 48)
                }
                Spacer()
                if direction == .right || direction == .center {
                    warningBadge(iconAlignment: .topTrailing, iconEdgePadding: .trailing)
                        .padding(.trailing, 48)
                }
            }
            .padding(.bottom, 140)
        }
        .offset(y: slideOffset)
    }

    private func warningBadge(iconAlignment: Alignment, iconEdgePadding: Edge.Set) -> some View {
        ZStack(alignment: iconAlignment) {
            CameraPreviewView(session: session) {
                withAnimation(.easeIn(duration: 0.3)) {
                    cameraOpacity = 1
                }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    slideOffset = 0
                }
            }
            .opacity(cameraOpacity)

            if let url = Bundle.module.url(forResource: "warning_icon", withExtension: "png"),
               let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 34, height: 34)
                    .padding(.top, 40)
                    .padding(iconEdgePadding, 40)
                    .opacity(iconOpacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                            iconOpacity = 0.15
                        }
                    }
            }
        }
        .frame(width: 220, height: 220)
        .background(Color.black)
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
                endRadius: 110
            )
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 6)
    }
}
