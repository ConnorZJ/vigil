import XCTest
@testable import Vigil

final class SessionSnapshotTests: XCTestCase {
    func testSnapshotRequiresCoreFields() throws {
        let snapshot = SessionSnapshot(
            sessionId: "1",
            sessionTitle: "title",
            projectPath: "/tmp/project",
            projectName: "project",
            terminalApp: "ghostty",
            status: .running,
            updatedAt: Date()
        )

        XCTAssertEqual(snapshot.projectName, "project")
        XCTAssertEqual(snapshot.status, .running)
    }
}
