import Foundation
import XCTest
@testable import Vigil

final class NotificationPolicyTests: XCTestCase {
    func testRunningDoesNotNotify() {
        let policy = NotificationPolicy()
        let current = makeSnapshot(status: .running)

        XCTAssertFalse(policy.shouldNotify(previous: nil, current: current))
    }

    func testWaitingInputPermissionErrorAndCompleteNotify() {
        let policy = NotificationPolicy()

        XCTAssertTrue(policy.shouldNotify(previous: nil, current: makeSnapshot(status: .waitingInput)))
        XCTAssertTrue(policy.shouldNotify(previous: nil, current: makeSnapshot(status: .permission)))
        XCTAssertTrue(policy.shouldNotify(previous: nil, current: makeSnapshot(status: .error)))
        XCTAssertTrue(policy.shouldNotify(previous: nil, current: makeSnapshot(status: .complete)))
    }

    func testDuplicateStatusDoesNotRenotifyWithoutStatusChange() {
        let policy = NotificationPolicy()
        let previous = makeSnapshot(status: .waitingInput)
        let current = makeSnapshot(status: .waitingInput)

        XCTAssertFalse(policy.shouldNotify(previous: previous, current: current))
    }

    private func makeSnapshot(status: SessionStatus) -> SessionSnapshot {
        SessionSnapshot(
            sessionId: "session-1",
            sessionTitle: "title",
            projectPath: "/tmp/project",
            projectName: "project",
            terminalApp: "ghostty",
            status: status,
            updatedAt: FixedClock().now
        )
    }
}
