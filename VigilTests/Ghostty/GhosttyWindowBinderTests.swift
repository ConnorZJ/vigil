import CoreGraphics
import Foundation
import XCTest
@testable import Vigil

final class GhosttyWindowBinderTests: XCTestCase {
    func testBindingStoresWindowSignature() throws {
        let root = temporaryDirectory()
        let persistence = BindingPersistence(fileStore: JSONFileStore(), paths: Paths(rootURL: root))
        let binder = GhosttyWindowBinder(persistence: persistence, clock: FixedClock())
        let window = GhosttyWindowDescriptor(title: "vigil", frame: CGRect(x: 1, y: 2, width: 3, height: 4), isFocused: true)

        try binder.bind(window: window, to: "session-1")

        let signature = try XCTUnwrap(binder.binding(for: "session-1"))
        XCTAssertEqual(signature.title, "vigil")
    }

    func testInvalidatedWindowRemovesBinding() throws {
        let root = temporaryDirectory()
        let persistence = BindingPersistence(fileStore: JSONFileStore(), paths: Paths(rootURL: root))
        let binder = GhosttyWindowBinder(persistence: persistence, clock: FixedClock())
        let window = GhosttyWindowDescriptor(title: "vigil", frame: CGRect(x: 1, y: 2, width: 3, height: 4), isFocused: true)

        try binder.bind(window: window, to: "session-1")
        try binder.invalidateBinding(for: "session-1")

        XCTAssertNil(binder.binding(for: "session-1"))
    }

    func testBinderProducesRematchCandidateAfterRelaunch() throws {
        let root = temporaryDirectory()
        let persistence = BindingPersistence(fileStore: JSONFileStore(), paths: Paths(rootURL: root))
        let binder = GhosttyWindowBinder(persistence: persistence, clock: FixedClock())
        let window = GhosttyWindowDescriptor(title: "vigil", frame: CGRect(x: 10, y: 20, width: 500, height: 400), isFocused: true)

        try binder.bind(window: window, to: "session-1")

        let reloadedBinder = GhosttyWindowBinder(persistence: persistence, clock: FixedClock())
        let candidate = reloadedBinder.rematchCandidate(
            for: "session-1",
            among: [window, GhosttyWindowDescriptor(title: "other", frame: .zero, isFocused: false)]
        )

        XCTAssertEqual(candidate?.title, "vigil")
    }
}
