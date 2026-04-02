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
}
