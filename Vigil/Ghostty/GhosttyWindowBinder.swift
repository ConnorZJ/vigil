import Foundation

final class GhosttyWindowBinder {
    private let persistence: BindingPersisting
    private let clock: TimeProviding
    private var bindings: [String: WindowSignature]

    init(persistence: BindingPersisting, clock: TimeProviding = SystemTimeProvider()) {
        self.persistence = persistence
        self.clock = clock
        self.bindings = (try? persistence.load()) ?? [:]
    }

    func bind(window: GhosttyWindowDescriptor, to sessionId: String) throws {
        bindings[sessionId] = WindowSignature(
            title: window.title,
            frame: CGRectCodable(window.frame),
            observedAt: clock.now
        )
        try persistence.save(bindings)
    }

    func binding(for sessionId: String) -> WindowSignature? {
        bindings[sessionId]
    }

    func invalidateBinding(for sessionId: String) throws {
        bindings.removeValue(forKey: sessionId)
        try persistence.save(bindings)
    }

    func rematchCandidate(for sessionId: String, among windows: [GhosttyWindowDescriptor]) -> GhosttyWindowDescriptor? {
        guard let signature = bindings[sessionId] else {
            return nil
        }

        return windows.max { lhs, rhs in
            rematchScore(for: lhs, signature: signature) < rematchScore(for: rhs, signature: signature)
        }
    }

    private func rematchScore(for window: GhosttyWindowDescriptor, signature: WindowSignature) -> Int {
        var score = 0

        if window.title == signature.title {
            score += 100
        }

        let signatureRect = CGRect(
            x: signature.frame.x,
            y: signature.frame.y,
            width: signature.frame.width,
            height: signature.frame.height
        )
        let distance = abs(signatureRect.origin.x - window.frame.origin.x) + abs(signatureRect.origin.y - window.frame.origin.y)
        if distance < 20 {
            score += 50
        }

        return score
    }
}
