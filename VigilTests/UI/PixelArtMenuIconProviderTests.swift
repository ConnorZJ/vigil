import AppKit
import XCTest
@testable import Vigil

final class PixelArtMenuIconProviderTests: XCTestCase {
    func testProviderGeneratesImageForEveryMenuState() {
        let provider = PixelArtMenuIconProvider()

        for state in [MenuBarIconState.idle, .running, .waitingInput, .permission, .complete, .error] {
            let image = provider.image(for: state)
            XCTAssertNotNil(image)
            XCTAssertEqual(image?.size.width, 16)
            XCTAssertEqual(image?.size.height, 16)
            XCTAssertEqual(image?.isTemplate, false)
        }
    }
}
