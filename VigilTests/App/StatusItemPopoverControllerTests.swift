import XCTest
@testable import Vigil

final class StatusItemPopoverControllerTests: XCTestCase {
    func testToggleSwitchesBetweenClosedAndOpen() {
        var state = PopoverVisibility.closed

        state.toggle()
        XCTAssertEqual(state, .open)

        state.toggle()
        XCTAssertEqual(state, .closed)
    }

    func testActionDismissPolicyOnlyClosesAfterSuccessfulJump() {
        XCTAssertTrue(PopoverDismissPolicy.shouldClose(for: .jump, succeeded: true))
        XCTAssertFalse(PopoverDismissPolicy.shouldClose(for: .jump, succeeded: false))
        XCTAssertFalse(PopoverDismissPolicy.shouldClose(for: .bind, succeeded: true))
        XCTAssertFalse(PopoverDismissPolicy.shouldClose(for: .refresh, succeeded: true))
        XCTAssertFalse(PopoverDismissPolicy.shouldClose(for: .accessibility, succeeded: true))
    }
}
