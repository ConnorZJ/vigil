import XCTest
@testable import Vigil

final class SessionPriorityTests: XCTestCase {
    func testErrorOutranksWaitingInput() {
        XCTAssertGreaterThan(
            SessionPriority(status: .error).value,
            SessionPriority(status: .waitingInput).value
        )
    }

    func testRunningDoesNotRequireAttention() {
        XCTAssertFalse(SessionStatus.running.requiresAttention)
    }
}
