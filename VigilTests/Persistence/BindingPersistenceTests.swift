import Foundation
import XCTest
@testable import Vigil

final class BindingPersistenceTests: XCTestCase {
    func testBindingPersistenceSavesAndLoadsBindings() throws {
        let root = temporaryDirectory()
        let persistence = BindingPersistence(fileStore: JSONFileStore(), paths: Paths(rootURL: root))
        let bindings = [
            "session-1": WindowSignature(
                title: "Ghostty",
                frame: CGRectCodable(x: 1, y: 2, width: 3, height: 4),
                observedAt: FixedClock().now
            )
        ]

        try persistence.save(bindings)

        let loaded = try persistence.load()
        XCTAssertEqual(loaded, bindings)
    }

    func testBindingPersistencePersistsDeletion() throws {
        let root = temporaryDirectory()
        let persistence = BindingPersistence(fileStore: JSONFileStore(), paths: Paths(rootURL: root))

        try persistence.save([
            "session-1": WindowSignature(
                title: "Ghostty",
                frame: CGRectCodable(x: 1, y: 2, width: 3, height: 4),
                observedAt: FixedClock().now
            )
        ])
        try persistence.save([:])

        XCTAssertEqual(try persistence.load(), [String: WindowSignature]())
    }
}
