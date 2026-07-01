import Foundation

enum PrivacyState {
    case safe
    case warning
    case privacyMode
}

final class PrivacyStateMachine {
    private let warningThreshold: TimeInterval = 3.0
    private let privacyThreshold: TimeInterval = 5.0
    private let flickerGrace: TimeInterval = 0.4

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
            onStateChanged?(newState)
        }
        if newState != .safe {
            onDirectionUpdate?(direction)
        }
    }
}
