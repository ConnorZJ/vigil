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
}
