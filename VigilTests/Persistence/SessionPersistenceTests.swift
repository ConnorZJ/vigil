import Foundation
import XCTest
@testable import Vigil

final class SessionPersistenceTests: XCTestCase {
    func testPersistenceRestoresActiveSessions() throws {
        let root = temporaryDirectory()
        let persistence = SessionPersistence(fileStore: JSONFileStore(), paths: Paths(rootURL: root))
        let snapshot = SessionSnapshot(
            sessionId: "session-1",
            sessionTitle: "title",
            projectPath: "/tmp/project",
            projectName: "project",
            terminalApp: "ghostty",
            status: .running,
            updatedAt: FixedClock().now
        )

        try persistence.save([snapshot])

        XCTAssertEqual(try persistence.load(), [snapshot])
    }

    func testPersistenceDropsExpiredCompletedSessions() throws {
        let root = temporaryDirectory()
        let clock = FixedClock(now: Date(timeIntervalSince1970: 1_712_000_000))
        let persistence = SessionPersistence(fileStore: JSONFileStore(), paths: Paths(rootURL: root))
        let expired = SessionSnapshot(
            sessionId: "session-1",
            sessionTitle: "title",
            projectPath: "/tmp/project",
            projectName: "project",
            terminalApp: "ghostty",
            status: .complete,
            updatedAt: clock.now.addingTimeInterval(-(10 * 60 + 1))
        )

        try persistence.save([expired])

        XCTAssertEqual(try persistence.load(now: clock.now), [SessionSnapshot]())
    }

    func testPersistenceRetainsStaleFlag() throws {
        let root = temporaryDirectory()
        let persistence = SessionPersistence(fileStore: JSONFileStore(), paths: Paths(rootURL: root))
        let snapshot = SessionSnapshot(
            sessionId: "session-1",
            sessionTitle: "title",
            projectPath: "/tmp/project",
            projectName: "project",
            terminalApp: "ghostty",
            status: .running,
            updatedAt: FixedClock().now,
            isStale: true
        )

        try persistence.save([snapshot])

        XCTAssertEqual(try persistence.load().first?.isStale, true)
    }
}
