import SwiftUI

struct WarningOverlayView: View {
    let direction: IntruderDirection
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 0) {
            switch direction {
            case .left:
                edgeBar(isLeft: true)
                Spacer()
            case .right:
                Spacer()
                edgeBar(isLeft: false)
            case .center:
                edgeBar(isLeft: true)
                Spacer()
                edgeBar(isLeft: false)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private func edgeBar(isLeft: Bool) -> some View {
        ZStack(alignment: isLeft ? .leading : .trailing) {
            // 그라디언트 배경 (엣지에서 안쪽으로 fade)
            LinearGradient(
                colors: [
                    Color.red.opacity(pulse ? 0.72 : 0.38),
                    Color.orange.opacity(pulse ? 0.28 : 0.10),
                    Color.clear
                ],
                startPoint: isLeft ? .leading : .trailing,
                endPoint: isLeft ? .trailing : .leading
            )

            VStack(spacing: 16) {
                Spacer()

                // 경고 아이콘 (warning_icon.png)
                Image("warning_icon", bundle: .module)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .opacity(pulse ? 1.0 : 0.45)
                    .shadow(color: .red.opacity(0.8), radius: pulse ? 18 : 6)

                Text("주시자 감지")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(pulse ? 1.0 : 0.6)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(isLeft ? .leading : .trailing, 12)
        }
        .frame(width: 130)
    }
}
