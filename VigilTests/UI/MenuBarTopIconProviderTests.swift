import AppKit
import XCTest
@testable import Vigil

final class MenuBarTopIconProviderTests: XCTestCase {
    func testProviderGeneratesImageForEveryTopBarState() {
        let provider = MenuBarTopIconProvider()

        for state in [MenuBarIconState.idle, .running, .waitingInput, .permission, .complete, .error] {
            let image = provider.image(for: state)
            XCTAssertNotNil(image)
            XCTAssertEqual(image?.size.width, 16)
            XCTAssertEqual(image?.size.height, 16)
            XCTAssertEqual(image?.isTemplate, false)
        }
    }

    func testPermissionAndWaitingStatesAreExplicitlyAddressed() {
        let provider = MenuBarTopIconProvider()

        let waitingImage = provider.image(for: .waitingInput)
        let permissionImage = provider.image(for: .permission)

        XCTAssertNotNil(waitingImage)
        XCTAssertNotNil(permissionImage)
    }

    func testAnimationFrameCountsFollowPolicy() {
        let provider = MenuBarTopIconProvider()

        XCTAssertEqual(provider.frameCount(for: .idle), 1)
        XCTAssertEqual(provider.frameCount(for: .running), 2)
        XCTAssertEqual(provider.frameCount(for: .waitingInput), 2)
        XCTAssertEqual(provider.frameCount(for: .permission), 2)
        XCTAssertEqual(provider.frameCount(for: .complete), 2)
        XCTAssertEqual(provider.frameCount(for: .error), 2)
    }
}
