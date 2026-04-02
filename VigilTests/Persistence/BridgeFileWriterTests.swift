import Foundation
import XCTest
@testable import Vigil

final class BridgeFileWriterTests: XCTestCase {
    func testBridgeFileContainsPortAndToken() throws {
        let root = temporaryDirectory()
        let writer = BridgeFileWriter(paths: Paths(rootURL: root), clock: FixedClock())

        try writer.write(port: 48127, token: "abc")

        let data = try Data(contentsOf: root.appendingPathComponent(".config/vigil/bridge.json"))
        let contents = String(decoding: data, as: UTF8.self)

        XCTAssertTrue(contents.contains("48127"))
        XCTAssertTrue(contents.contains("abc"))
        XCTAssertTrue(contents.contains("updatedAt"))
    }
}
