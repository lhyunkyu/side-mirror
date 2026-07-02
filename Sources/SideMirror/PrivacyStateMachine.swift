import Foundation

private func timestamp() -> String {
    let f = DateFormatter()
    f.dateFormat = "HH:mm:ss.SSS"
    return f.string(from: Date())
}

enum PrivacyState {
    case safe
    case warning
    case privacyMode
}

final class PrivacyStateMachine {
    var warningThreshold: TimeInterval = 0.6
    var privacyOffset: TimeInterval = 1.0
    var privacyThreshold: TimeInterval { warningThreshold + privacyOffset }
    private let flickerGrace: TimeInterval = 1.0

    private(set) var state: PrivacyState = .safe
    private var intrusionStartedAt: Date?
    private var lastIntrusionSeenAt: Date?

    var onStateChanged: ((PrivacyState) -> Void)?
    var onDirectionUpdate: ((IntruderDirection?) -> Void)?

    func update(with result: DetectionResult, now: Date = Date()) {
        let intruding = result.totalCount >= 2

        if intruding {
            lastIntrusionSeenAt = now
            if intrusionStartedAt == nil {
                intrusionStartedAt = now
            }
        } else if let lastSeen = lastIntrusionSeenAt, now.timeIntervalSince(lastSeen) < flickerGrace {
            // brief detection dropout, keep treating as continuous intrusion
        } else {
            intrusionStartedAt = nil
            lastIntrusionSeenAt = nil
            apply(.safe, direction: nil)
            return
        }

        guard let startedAt = intrusionStartedAt else { return }
        let elapsed = now.timeIntervalSince(startedAt)

        if elapsed >= privacyThreshold {
            apply(.privacyMode, direction: result.intruderDirection)
        } else if elapsed >= warningThreshold {
            apply(.warning, direction: result.intruderDirection)
        }
    }

    func reset() {
        intrusionStartedAt = nil
        lastIntrusionSeenAt = nil
        apply(.safe, direction: nil)
    }

    private func apply(_ newState: PrivacyState, direction: IntruderDirection?) {
        let stateDidChange = newState != state
        state = newState
        if stateDidChange {
            let label: String
            switch newState {
            case .safe:        label = "✅ SAFE"
            case .warning:     label = "⚠️  WARNING"
            case .privacyMode: label = "🔴 PRIVACY MODE"
            }
            print("[\(timestamp())] 상태 변경 → \(label)")
            onStateChanged?(newState)
        }
        if newState != .safe {
            onDirectionUpdate?(direction)
        }
    }
}
