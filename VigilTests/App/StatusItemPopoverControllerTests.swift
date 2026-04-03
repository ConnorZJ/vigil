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

    func testOutsideClickDecisionDoesNotCloseForPopoverOrButtonWindow() {
        XCTAssertFalse(
            PopoverOutsideClickDecision.shouldCloseLocalClick(
                eventWindowNumber: 11,
                popoverWindowNumber: 11,
                buttonWindowNumber: 22
            )
        )

        XCTAssertFalse(
            PopoverOutsideClickDecision.shouldCloseLocalClick(
                eventWindowNumber: 22,
                popoverWindowNumber: 11,
                buttonWindowNumber: 22
            )
        )
    }

    func testOutsideClickDecisionClosesForDifferentWindow() {
        XCTAssertTrue(
            PopoverOutsideClickDecision.shouldCloseLocalClick(
                eventWindowNumber: 33,
                popoverWindowNumber: 11,
                buttonWindowNumber: 22
            )
        )
    }

    func testDismissMonitorInstallsAndRemovesLocalAndGlobalMonitors() {
        let eventMonitor = PopoverClickEventMonitorSpy()
        let dismissMonitor = PopoverDismissMonitor(eventMonitor: eventMonitor) {}

        dismissMonitor.start(popoverWindowNumber: 11, buttonWindowNumber: 22)

        XCTAssertEqual(eventMonitor.addedLocalMonitorCount, 1)
        XCTAssertEqual(eventMonitor.addedGlobalMonitorCount, 1)

        dismissMonitor.stop()

        XCTAssertEqual(eventMonitor.removedMonitorCount, 2)
    }

    func testDismissMonitorClosesOnFirstOutsideClickOnly() {
        let eventMonitor = PopoverClickEventMonitorSpy()
        var closeCount = 0
        let dismissMonitor = PopoverDismissMonitor(eventMonitor: eventMonitor) {
            closeCount += 1
        }

        dismissMonitor.start(popoverWindowNumber: 11, buttonWindowNumber: 22)

        eventMonitor.localHandler?(11)
        eventMonitor.localHandler?(22)
        XCTAssertEqual(closeCount, 0)

        eventMonitor.localHandler?(33)
        XCTAssertEqual(closeCount, 1)

        eventMonitor.globalHandler?()
        XCTAssertEqual(closeCount, 2)
    }
}

private final class PopoverClickEventMonitorSpy: PopoverClickEventMonitoring {
    var addedLocalMonitorCount = 0
    var addedGlobalMonitorCount = 0
    var removedMonitorCount = 0
    var localHandler: ((Int) -> Void)?
    var globalHandler: (() -> Void)?

    func addLocalMouseDownMonitor(handler: @escaping (Int) -> Void) -> Any {
        addedLocalMonitorCount += 1
        localHandler = handler
        return "local-monitor"
    }

    func addGlobalMouseDownMonitor(handler: @escaping () -> Void) -> Any {
        addedGlobalMonitorCount += 1
        globalHandler = handler
        return "global-monitor"
    }

    func removeMonitor(_ monitor: Any) {
        removedMonitorCount += 1
    }
}
