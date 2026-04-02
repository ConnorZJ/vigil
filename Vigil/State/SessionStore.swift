import Foundation

final class SessionStore {
    private let clock: TimeProviding
    private var snapshotsBySessionId: [String: SessionSnapshot] = [:]
    private var latestEventAtBySessionId: [String: Date] = [:]
    private var seenEventIds: Set<String> = []

    init(clock: TimeProviding = SystemTimeProvider()) {
        self.clock = clock
    }

    var primarySession: SessionSnapshot? {
        snapshotsBySessionId.values.max { lhs, rhs in
            compare(lhs, rhs) == .orderedAscending
        }
    }

    var allSnapshots: [SessionSnapshot] {
        snapshotsBySessionId.values.sorted { lhs, rhs in
            compare(lhs, rhs) == .orderedDescending
        }
    }

    func snapshot(for sessionId: String) -> SessionSnapshot? {
        snapshotsBySessionId[sessionId]
    }

    func apply(event: SessionEvent) {
        guard seenEventIds.insert(event.eventId).inserted else {
            return
        }

        let sessionId = event.session.sessionId

        if let latest = latestEventAtBySessionId[sessionId], event.sentAt < latest {
            return
        }

        latestEventAtBySessionId[sessionId] = event.sentAt

        if event.eventType == "session.closed" {
            snapshotsBySessionId.removeValue(forKey: sessionId)
            latestEventAtBySessionId.removeValue(forKey: sessionId)
            return
        }

        var snapshot = event.session
        snapshot = SessionSnapshot(
            sessionId: snapshot.sessionId,
            sessionTitle: snapshot.sessionTitle,
            projectPath: snapshot.projectPath,
            projectName: snapshot.projectName,
            terminalApp: snapshot.terminalApp,
            status: snapshot.status,
            updatedAt: event.sentAt,
            windowHint: snapshot.windowHint,
            workspaceHint: snapshot.workspaceHint,
            lastError: snapshot.lastError,
            requiresAttentionReason: snapshot.requiresAttentionReason,
            isStale: false
        )
        snapshotsBySessionId[sessionId] = snapshot
    }

    func markStaleSessions(now: Date? = nil) {
        let current = now ?? clock.now

        snapshotsBySessionId = snapshotsBySessionId.mapValues { snapshot in
            let isStale = current.timeIntervalSince(snapshot.updatedAt) > 45
            return SessionSnapshot(
                sessionId: snapshot.sessionId,
                sessionTitle: snapshot.sessionTitle,
                projectPath: snapshot.projectPath,
                projectName: snapshot.projectName,
                terminalApp: snapshot.terminalApp,
                status: snapshot.status,
                updatedAt: snapshot.updatedAt,
                windowHint: snapshot.windowHint,
                workspaceHint: snapshot.workspaceHint,
                lastError: snapshot.lastError,
                requiresAttentionReason: snapshot.requiresAttentionReason,
                isStale: isStale
            )
        }
    }

    func applyRetentionPolicy(now: Date? = nil) {
        let current = now ?? clock.now

        snapshotsBySessionId = snapshotsBySessionId.filter { _, snapshot in
            guard snapshot.status == .complete else {
                return true
            }

            return current.timeIntervalSince(snapshot.updatedAt) <= 10 * 60
        }
    }

    private func compare(_ lhs: SessionSnapshot, _ rhs: SessionSnapshot) -> ComparisonResult {
        let leftPriority = SessionPriority(status: lhs.status, isStale: lhs.isStale).value
        let rightPriority = SessionPriority(status: rhs.status, isStale: rhs.isStale).value

        if leftPriority != rightPriority {
            return leftPriority < rightPriority ? .orderedAscending : .orderedDescending
        }

        if lhs.updatedAt != rhs.updatedAt {
            return lhs.updatedAt < rhs.updatedAt ? .orderedAscending : .orderedDescending
        }

        return lhs.sessionId < rhs.sessionId ? .orderedAscending : .orderedDescending
    }
}
