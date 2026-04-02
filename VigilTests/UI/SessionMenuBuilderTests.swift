import Foundation
import XCTest
@testable import Vigil

final class SessionMenuBuilderTests: XCTestCase {
    func testPrimarySessionDeterminesTopIconState() {
        let builder = SessionMenuBuilder()
        let now = Date(timeIntervalSince1970: 1_712_000_000)
        let presentation = builder.build(
            from: [
                makeSnapshot(id: "running", status: .running, updatedAt: now),
                makeSnapshot(id: "waiting", status: .waitingInput, updatedAt: now)
            ],
            now: now
        )

        XCTAssertEqual(presentation.iconState, .waitingInput)
    }

    func testSessionsAreGroupedIntoExpectedSections() {
        let builder = SessionMenuBuilder()
        let now = Date(timeIntervalSince1970: 1_712_000_000)
        let presentation = builder.build(
            from: [
                makeSnapshot(id: "error", status: .error, updatedAt: now),
                makeSnapshot(id: "running", status: .running, updatedAt: now),
                makeSnapshot(id: "complete", status: .complete, updatedAt: now)
            ],
            now: now
        )

        XCTAssertEqual(presentation.sections.map(\.kind), [.summary, .needsAttention, .running, .recentlyCompleted])
    }

    func testRowViewModelShowsRelativeAgeAndProjectName() throws {
        let builder = SessionMenuBuilder()
        let updatedAt = Date(timeIntervalSince1970: 1_712_000_000 - 30)
        let now = Date(timeIntervalSince1970: 1_712_000_000)
        let presentation = builder.build(
            from: [makeSnapshot(id: "running", status: .running, updatedAt: updatedAt)],
            now: now
        )

        let row = try XCTUnwrap(presentation.sections.first(where: { $0.kind == .running })?.rows.first)
        XCTAssertEqual(row.projectName, "project-running")
        XCTAssertEqual(row.relativeUpdatedText, "30s ago")
    }

    private func makeSnapshot(id: String, status: SessionStatus, updatedAt: Date) -> SessionSnapshot {
        SessionSnapshot(
            sessionId: id,
            sessionTitle: "title-\(id)",
            projectPath: "/tmp/project-\(id)",
            projectName: "project-\(id)",
            terminalApp: "ghostty",
            status: status,
            updatedAt: updatedAt,
            requiresAttentionReason: status.requiresAttention ? "Needs attention" : nil
        )
    }
}
