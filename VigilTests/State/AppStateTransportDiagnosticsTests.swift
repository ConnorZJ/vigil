import Foundation
import XCTest
@testable import Vigil

final class AppStateTransportDiagnosticsTests: XCTestCase {
    func testDiagnosticsExposeTransportFacts() {
        let now = Date(timeIntervalSince1970: 1_712_000_000)
        let transport = FakeTransportServer(
            port: 48127,
            token: "secret",
            isListening: true,
            bridgeWriteSucceeded: true,
            lastErrorStage: .auth,
            lastErrorMessage: "bad token",
            lastReceivedEventAt: now.addingTimeInterval(-5)
        )

        let appState = AppState(
            clock: FixedClock(now: now),
            sessionStore: SessionStore(clock: FixedClock(now: now)),
            transportServer: transport,
            permissionService: FakePermissionService(status: .granted),
            ghosttyWindowQueryService: FakeGhosttyWindowQueryService(),
            ghosttyWindowBinder: GhosttyWindowBinder(persistence: InMemoryBindingPersistence(), clock: FixedClock(now: now)),
            ghosttyWindowActivator: FakeGhosttyWindowActivator(),
            paths: Paths(rootURL: temporaryDirectory())
        )

        let diagnostics = appState.diagnosticsSnapshot

        XCTAssertTrue(diagnostics.transportStatus.contains("48127"))
        XCTAssertTrue(diagnostics.bridgeStatus.contains("written"))
        XCTAssertEqual(diagnostics.lastEventText, "5s ago")
        XCTAssertEqual(diagnostics.lastTransportError, "auth: bad token")
    }

    func testBootstrapRestoresPersistedSessionsBeforeTransportStarts() {
        let now = Date(timeIntervalSince1970: 1_712_000_000)
        let store = SessionStore(clock: FixedClock(now: now))
        let restoredSnapshot = SessionSnapshot(
            sessionId: "session-1",
            sessionTitle: "title",
            projectPath: "/tmp/project",
            projectName: "project",
            terminalApp: "ghostty",
            status: .running,
            updatedAt: now.addingTimeInterval(-5)
        )
        let transport = FakeTransportServer(
            port: 48127,
            token: "secret",
            isListening: true,
            bridgeWriteSucceeded: true,
            lastErrorStage: nil,
            lastErrorMessage: nil,
            lastReceivedEventAt: nil
        )
        transport.onStart = {
            XCTAssertEqual(store.snapshot(for: "session-1")?.status, .running)
        }

        let appState = AppState(
            clock: FixedClock(now: now),
            sessionStore: store,
            sessionPersistence: FakeSessionPersistence(snapshots: [restoredSnapshot]),
            transportServer: transport,
            permissionService: FakePermissionService(status: .granted),
            ghosttyWindowQueryService: FakeGhosttyWindowQueryService(),
            ghosttyWindowBinder: GhosttyWindowBinder(persistence: InMemoryBindingPersistence(), clock: FixedClock(now: now)),
            ghosttyWindowActivator: FakeGhosttyWindowActivator(),
            paths: Paths(rootURL: temporaryDirectory())
        )

        appState.bootstrap()

        XCTAssertEqual(appState.sessionSnapshots.map(\.sessionId), ["session-1"])
    }

    func testSessionSnapshotsDropCompletedSessionsPastRetentionWindow() {
        let now = Date(timeIntervalSince1970: 1_712_000_000)
        let store = SessionStore(clock: FixedClock(now: now))
        store.apply(event: SessionEvent(
            eventId: UUID().uuidString,
            eventType: "session.completed",
            sentAt: now.addingTimeInterval(-(10 * 60 + 1)),
            session: SessionSnapshot(
                sessionId: "session-1",
                sessionTitle: "title",
                projectPath: "/tmp/project",
                projectName: "project",
                terminalApp: "ghostty",
                status: .complete,
                updatedAt: now.addingTimeInterval(-(10 * 60 + 1))
            )
        ))
        let appState = AppState(
            clock: FixedClock(now: now),
            sessionStore: store,
            transportServer: FakeTransportServer(
                port: 48127,
                token: "secret",
                isListening: true,
                bridgeWriteSucceeded: true,
                lastErrorStage: nil,
                lastErrorMessage: nil,
                lastReceivedEventAt: nil
            ),
            permissionService: FakePermissionService(status: .granted),
            ghosttyWindowQueryService: FakeGhosttyWindowQueryService(),
            ghosttyWindowBinder: GhosttyWindowBinder(persistence: InMemoryBindingPersistence(), clock: FixedClock(now: now)),
            ghosttyWindowActivator: FakeGhosttyWindowActivator(),
            paths: Paths(rootURL: temporaryDirectory())
        )

        XCTAssertTrue(appState.sessionSnapshots.isEmpty)
    }

    func testBootstrapSchedulesAutomaticHousekeepingThatRemovesExpiredCompletedSessions() {
        let now = Date(timeIntervalSince1970: 1_712_000_000)
        let clock = MutableClock(now: now)
        let scheduler = FakeRepeatingTaskScheduler()
        let store = SessionStore(clock: clock)
        store.apply(event: SessionEvent(
            eventId: UUID().uuidString,
            eventType: "session.completed",
            sentAt: now,
            session: SessionSnapshot(
                sessionId: "session-1",
                sessionTitle: "title",
                projectPath: "/tmp/project",
                projectName: "project",
                terminalApp: "ghostty",
                status: .complete,
                updatedAt: now
            )
        ))
        let appState = AppState(
            clock: clock,
            sessionStore: store,
            transportServer: FakeTransportServer(
                port: 48127,
                token: "secret",
                isListening: true,
                bridgeWriteSucceeded: true,
                lastErrorStage: nil,
                lastErrorMessage: nil,
                lastReceivedEventAt: nil
            ),
            permissionService: FakePermissionService(status: .granted),
            ghosttyWindowQueryService: FakeGhosttyWindowQueryService(),
            ghosttyWindowBinder: GhosttyWindowBinder(persistence: InMemoryBindingPersistence(), clock: clock),
            ghosttyWindowActivator: FakeGhosttyWindowActivator(),
            paths: Paths(rootURL: temporaryDirectory()),
            housekeepingScheduler: scheduler,
            housekeepingInterval: 30
        )
        var changeCount = 0
        appState.onChange = {
            changeCount += 1
        }

        appState.bootstrap()
        XCTAssertEqual(scheduler.scheduledIntervals, [30])
        XCTAssertNotNil(store.snapshot(for: "session-1"))

        let changesAfterBootstrap = changeCount
        clock.now = now.addingTimeInterval(10 * 60 + 1)
        scheduler.fire()

        XCTAssertNil(store.snapshot(for: "session-1"))
        XCTAssertEqual(changeCount, changesAfterBootstrap + 1)
    }

    func testTransportStateChangesNotifyOnMainThread() {
        let now = Date(timeIntervalSince1970: 1_712_000_000)
        let transport = FakeTransportServer(
            port: 48127,
            token: "secret",
            isListening: true,
            bridgeWriteSucceeded: true,
            lastErrorStage: nil,
            lastErrorMessage: nil,
            lastReceivedEventAt: nil
        )
        let appState = AppState(
            clock: FixedClock(now: now),
            sessionStore: SessionStore(clock: FixedClock(now: now)),
            transportServer: transport,
            permissionService: FakePermissionService(status: .granted),
            ghosttyWindowQueryService: FakeGhosttyWindowQueryService(),
            ghosttyWindowBinder: GhosttyWindowBinder(persistence: InMemoryBindingPersistence(), clock: FixedClock(now: now)),
            ghosttyWindowActivator: FakeGhosttyWindowActivator(),
            paths: Paths(rootURL: temporaryDirectory())
        )
        let callbackExpectation = expectation(description: "transport state change callback")
        var callbackOnMainThread = false
        appState.onChange = {
            callbackOnMainThread = Thread.isMainThread
            callbackExpectation.fulfill()
        }

        DispatchQueue.global().async {
            transport.onStateChange?()
        }

        wait(for: [callbackExpectation], timeout: 1)
        XCTAssertTrue(callbackOnMainThread)
    }
}

private final class FakeTransportServer: TransportServing {
    let port: Int?
    let token: String?
    let isListening: Bool
    let bridgeWriteSucceeded: Bool
    let lastErrorStage: TransportErrorStage?
    let lastErrorMessage: String?
    let lastReceivedEventAt: Date?
    var onStateChange: (() -> Void)?
    var onStart: (() -> Void)?

    init(
        port: Int?,
        token: String?,
        isListening: Bool,
        bridgeWriteSucceeded: Bool,
        lastErrorStage: TransportErrorStage?,
        lastErrorMessage: String?,
        lastReceivedEventAt: Date?
    ) {
        self.port = port
        self.token = token
        self.isListening = isListening
        self.bridgeWriteSucceeded = bridgeWriteSucceeded
        self.lastErrorStage = lastErrorStage
        self.lastErrorMessage = lastErrorMessage
        self.lastReceivedEventAt = lastReceivedEventAt
    }

    func start(port: Int) throws {
        onStart?()
    }
    func stop() {}
}

private struct FakeSessionPersistence: SessionSnapshotLoading {
    let snapshots: [SessionSnapshot]

    func load(now: Date) throws -> [SessionSnapshot] {
        snapshots
    }
}

private struct FakePermissionService: AXPermissionProviding {
    let status: AXPermissionStatus
    func requestAccessPrompt() {}
}

private struct FakeGhosttyWindowQueryService: GhosttyWindowQuerying {
    func currentWindows() throws -> [GhosttyWindowDescriptor] { [] }
    func frontmostWindow() throws -> GhosttyWindowDescriptor? { nil }
}

private struct InMemoryBindingPersistence: BindingPersisting {
    func load() throws -> [String: WindowSignature] { [:] }
    func save(_ bindings: [String: WindowSignature]) throws {}
}

private struct FakeGhosttyWindowActivator: GhosttyWindowActivating {
    func activateBestWindow(for snapshot: SessionSnapshot) throws {}
    func bindFrontmostWindow(to sessionId: String) throws {}
}

private final class MutableClock: TimeProviding {
    var now: Date

    init(now: Date) {
        self.now = now
    }
}

private final class FakeRepeatingTaskScheduler: RepeatingTaskScheduling {
    private(set) var scheduledIntervals: [TimeInterval] = []
    private var action: (() -> Void)?

    @discardableResult
    func scheduleRepeating(every interval: TimeInterval, _ action: @escaping () -> Void) -> RepeatingTask {
        scheduledIntervals.append(interval)
        self.action = action
        return FakeRepeatingTask()
    }

    func fire() {
        action?()
    }
}

private struct FakeRepeatingTask: RepeatingTask {
    func cancel() {}
}
