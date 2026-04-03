import Foundation
import XCTest
@testable import Vigil

final class SessionStoreTests: XCTestCase {
    func testHighestPriorityPrefersWaitingInputOverRunning() {
        let store = SessionStore(clock: FixedClock())

        store.apply(event: makeEvent(eventType: "session.started", sessionId: "a", status: .running))
        store.apply(event: makeEvent(eventType: "session.waiting_input", sessionId: "b", status: .waitingInput))

        XCTAssertEqual(store.primarySession?.sessionId, "b")
    }

    func testCompletedEventMovesSessionToComplete() {
        let store = SessionStore(clock: FixedClock())

        store.apply(event: makeEvent(eventType: "session.started", sessionId: "a", status: .running))
        store.apply(event: makeEvent(eventType: "session.completed", sessionId: "a", status: .complete))

        XCTAssertEqual(store.snapshot(for: "a")?.status, .complete)
    }

    func testClosedEventRemovesActiveSession() {
        let store = SessionStore(clock: FixedClock())

        store.apply(event: makeEvent(eventType: "session.started", sessionId: "a", status: .running))
        store.apply(event: makeEvent(eventType: "session.closed", sessionId: "a", status: .complete))

        XCTAssertNil(store.snapshot(for: "a"))
    }

    func testStaleSessionDoesNotOutrankFreshPeerWithSamePriority() {
        let staleDate = Date(timeIntervalSince1970: 1_712_000_000 - 60)
        let now = Date(timeIntervalSince1970: 1_712_000_000)
        let store = SessionStore(clock: FixedClock(now: now))

        store.apply(event: makeEvent(eventType: "session.waiting_input", sessionId: "stale", status: .waitingInput, sentAt: staleDate))
        store.apply(event: makeEvent(eventType: "session.waiting_input", sessionId: "fresh", status: .waitingInput, sentAt: now))
        store.markStaleSessions(now: now)

        XCTAssertEqual(store.primarySession?.sessionId, "fresh")
    }

    func testOlderSnapshotsDoNotRegressSessionState() {
        let now = Date(timeIntervalSince1970: 1_712_000_000)
        let store = SessionStore(clock: FixedClock(now: now))

        store.apply(event: makeEvent(eventType: "session.waiting_input", sessionId: "a", status: .waitingInput, sentAt: now))
        store.apply(event: makeEvent(eventType: "session.started", sessionId: "a", status: .running, sentAt: now.addingTimeInterval(-10)))

        XCTAssertEqual(store.snapshot(for: "a")?.status, .waitingInput)
    }

    func testRestoredSnapshotDoesNotOverwriteNewerLiveEvent() {
        let now = Date(timeIntervalSince1970: 1_712_000_000)
        let store = SessionStore(clock: FixedClock(now: now))

        store.apply(event: makeEvent(eventType: "session.waiting_input", sessionId: "a", status: .waitingInput, sentAt: now))
        store.restore(snapshot: SessionSnapshot(
            sessionId: "a",
            sessionTitle: "title-a",
            projectPath: "/tmp/project-a",
            projectName: "project-a",
            terminalApp: "ghostty",
            status: .running,
            updatedAt: now.addingTimeInterval(-30)
        ))

        XCTAssertEqual(store.snapshot(for: "a")?.status, .waitingInput)
    }

    private func makeEvent(
        eventType: String,
        sessionId: String,
        status: SessionStatus,
        sentAt: Date = FixedClock().now
    ) -> SessionEvent {
        let snapshot = SessionSnapshot(
            sessionId: sessionId,
            sessionTitle: "title-\(sessionId)",
            projectPath: "/tmp/project-\(sessionId)",
            projectName: "project-\(sessionId)",
            terminalApp: "ghostty",
            status: status,
            updatedAt: sentAt
        )

        return SessionEvent(
            eventId: UUID().uuidString,
            eventType: eventType,
            sentAt: sentAt,
            session: snapshot
        )
    }
}
