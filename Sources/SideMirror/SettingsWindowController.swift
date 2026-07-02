import Cocoa
import SwiftUI

private final class SettingsModel: ObservableObject {
    @Published var warningThreshold: Double
    @Published var privacyOffset: Double
    var onSave: ((Double, Double) -> Void)?
    var onReset: (() -> Void)?

    init(warningThreshold: Double, privacyOffset: Double) {
        self.warningThreshold = warningThreshold
        self.privacyOffset = privacyOffset
    }
}

private struct SettingsView: View {
    @ObservedObject var model: SettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            sliderSection(
                title: "화면 띄우기 민감도",
                subtitle: "다른 사람 감지 후 경고 화면이 뜨는 시간",
                value: $model.warningThreshold,
                range: 0.3...3.0,
                minLabel: "빠름", maxLabel: "느림"
            )

            sliderSection(
                title: "인식 후 자동 탭 시간",
                subtitle: "경고 후 바탕화면으로 전환되는 시간",
                value: $model.privacyOffset,
                range: 0.5...5.0,
                minLabel: "짧게", maxLabel: "길게"
            )

            Divider()

            HStack {
                Button("기본값으로 초기화") { model.onReset?() }
                    .buttonStyle(.bordered)
                Spacer()
                Button("저장") { model.onSave?(model.warningThreshold, model.privacyOffset) }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
            }
        }
        .padding(24)
        .frame(width: 320)
    }

    private func sliderSection(
        title: String,
        subtitle: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        minLabel: String,
        maxLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 13, weight: .medium))
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Text(String(format: "%.1f초", value.wrappedValue))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            Slider(value: value, in: range)
                .tint(.blue)
            HStack {
                Text(minLabel).font(.caption2).foregroundColor(.secondary)
                Spacer()
                Text(maxLabel).font(.caption2).foregroundColor(.secondary)
            }
        }
    }
}

final class SettingsWindowController {
    static let defaultWarning: Double = 1.0
    static let defaultPrivacyOffset: Double = 2.0

    private var window: NSWindow?
    private var model: SettingsModel?

    var onUpdate: ((Double, Double) -> Void)?

    func show(warningThreshold: Double, privacyOffset: Double) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let m = SettingsModel(warningThreshold: warningThreshold, privacyOffset: privacyOffset)
        m.onSave = { [weak self] w, p in
            self?.onUpdate?(w, p)
            self?.window?.close()
            self?.window = nil
            self?.model = nil
        }
        m.onReset = { [weak self] in
            self?.model?.warningThreshold = Self.defaultWarning
            self?.model?.privacyOffset = Self.defaultPrivacyOffset
        }
        model = m

        let hostingVC = NSHostingController(rootView: SettingsView(model: m))

        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "설정"
        panel.contentViewController = hostingVC
        panel.center()
        panel.isReleasedWhenClosed = false
        window = panel

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
