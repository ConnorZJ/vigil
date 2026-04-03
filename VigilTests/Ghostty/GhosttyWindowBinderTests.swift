import CoreGraphics
import Foundation
import XCTest
@testable import Vigil

final class GhosttyWindowBinderTests: XCTestCase {
    func testBindingStoresWindowSignature() throws {
        let root = temporaryDirectory()
        let persistence = BindingPersistence(fileStore: JSONFileStore(), paths: Paths(rootURL: root))
        let binder = GhosttyWindowBinder(persistence: persistence, clock: FixedClock())
        let window = GhosttyWindowDescriptor(
            title: "vigil",
            frame: CGRect(x: 1, y: 2, width: 3, height: 4),
            isFocused: true,
            cwd: "/tmp/vigil",
            tabTitle: "agent-2",
            tty: "/dev/ttys009"
        )

        try binder.bind(window: window, to: "session-1")

        let signature = try XCTUnwrap(binder.binding(for: "session-1"))
        XCTAssertEqual(signature.title, "vigil")
        XCTAssertEqual(signature.cwd, "/tmp/vigil")
        XCTAssertEqual(signature.tabTitle, "agent-2")
        XCTAssertEqual(signature.tty, "/dev/ttys009")
    }

    func testBindingPersistenceLoadsLegacyWindowSignatureWithoutTabFields() throws {
        let root = temporaryDirectory()
        let paths = Paths(rootURL: root)
        let legacyJSON = #"""
        {
          "session-1" : {
            "frame" : {
              "height" : 400,
              "width" : 500,
              "x" : 10,
              "y" : 20
            },
            "observedAt" : "2026-04-03T06:00:00Z",
            "title" : "vigil"
          }
        }
        """#
        try FileManager.default.createDirectory(at: paths.bindingPersistenceFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        try XCTUnwrap(legacyJSON.data(using: .utf8)).write(to: paths.bindingPersistenceFile)

        let binder = GhosttyWindowBinder(
            persistence: BindingPersistence(fileStore: JSONFileStore(), paths: paths),
            clock: FixedClock()
        )

        let signature = try XCTUnwrap(binder.binding(for: "session-1"))
        XCTAssertEqual(signature.title, "vigil")
        XCTAssertNil(signature.cwd)
        XCTAssertNil(signature.tabTitle)
        XCTAssertNil(signature.tty)
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
        let window = GhosttyWindowDescriptor(
            title: "vigil",
            frame: CGRect(x: 10, y: 20, width: 500, height: 400),
            isFocused: true,
            cwd: "/tmp/vigil",
            tabTitle: "agent-2",
            tty: "/dev/ttys009"
        )

        try binder.bind(window: window, to: "session-1")

        let reloadedBinder = GhosttyWindowBinder(persistence: persistence, clock: FixedClock())
        let candidate = reloadedBinder.rematchCandidate(
            for: "session-1",
            among: [
                GhosttyWindowDescriptor(title: "vigil", frame: CGRect(x: 10, y: 20, width: 500, height: 400), isFocused: false, cwd: "/tmp/vigil", tabTitle: "agent-1", tty: "/dev/ttys001"),
                window
            ]
        )

        XCTAssertEqual(candidate?.tabTitle, "agent-2")
    }
}
