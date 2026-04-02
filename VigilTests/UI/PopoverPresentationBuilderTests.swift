import Foundation
import XCTest
@testable import Vigil

final class PopoverPresentationBuilderTests: XCTestCase {
    func testSectionsAppearInExpectedOrder() {
        let builder = PopoverPresentationBuilder()
        let now = Date(timeIntervalSince1970: 1_712_000_000)
        let diagnostics = DiagnosticsSnapshot(
            transportStatus: "Listening on 127.0.0.1:48127",
            bridgeStatus: "~/.config/vigil/bridge.json",
            accessibilityStatus: "Granted",
            lastEventText: "5s ago",
            lastJumpError: nil
        )

        let presentation = builder.build(
            from: [
                makeSnapshot(id: "error", status: .error, updatedAt: now),
                makeSnapshot(id: "running", status: .running, updatedAt: now),
                makeSnapshot(id: "complete", status: .complete, updatedAt: now)
            ],
            diagnostics: diagnostics,
            now: now
        )

        XCTAssertEqual(
            presentation.sections.map(\.kind),
            [.summary, .needsAttention, .running, .recentlyCompleted, .diagnostics, .utilityActions]
        )
    }

    func testSummaryRespectsAggregateStatePrecedence() {
        let builder = PopoverPresentationBuilder()
        let now = Date(timeIntervalSince1970: 1_712_000_000)
        let presentation = builder.build(
            from: [
                makeSnapshot(id: "running", status: .running, updatedAt: now),
                makeSnapshot(id: "permission", status: .permission, updatedAt: now),
                makeSnapshot(id: "complete", status: .complete, updatedAt: now)
            ],
            diagnostics: makeDiagnostics(),
            now: now
        )

        XCTAssertEqual(presentation.summary.primaryStateLabel, "Permission Needed")
        XCTAssertEqual(presentation.summary.trackedSessionCount, 3)
        XCTAssertEqual(presentation.summary.attentionRequiredCount, 1)
    }

    func testSessionCardContainsRequiredFields() throws {
        let builder = PopoverPresentationBuilder()
        let now = Date(timeIntervalSince1970: 1_712_000_000)
        let presentation = builder.build(
            from: [makeSnapshot(id: "waiting", status: .waitingInput, updatedAt: now.addingTimeInterval(-30))],
            diagnostics: makeDiagnostics(),
            now: now
        )

        let card = try XCTUnwrap(presentation.sections.first(where: { $0.kind == .needsAttention })?.sessionCards.first)
        XCTAssertEqual(card.title, "title-waiting")
        XCTAssertEqual(card.projectName, "project-waiting")
        XCTAssertEqual(card.relativeUpdatedText, "30s ago")
        XCTAssertEqual(card.statusBadgeText, "Waiting for Input")
        XCTAssertEqual(card.iconState, .waitingInput)
        XCTAssertEqual(card.primaryActionSessionId, "waiting")
        XCTAssertEqual(card.bindActionSessionId, "waiting")
    }

    func testDiagnosticsContainAllRequiredFields() {
        let builder = PopoverPresentationBuilder()
        let diagnostics = DiagnosticsSnapshot(
            transportStatus: "Listening on 127.0.0.1:48127",
            bridgeStatus: "~/.config/vigil/bridge.json",
            accessibilityStatus: "Granted",
            lastEventText: "12s ago",
            lastJumpError: "No matching window"
        )

        let presentation = builder.build(from: [], diagnostics: diagnostics, now: Date())

        XCTAssertEqual(presentation.diagnostics.transportStatus, "Listening on 127.0.0.1:48127")
        XCTAssertEqual(presentation.diagnostics.bridgeStatus, "~/.config/vigil/bridge.json")
        XCTAssertEqual(presentation.diagnostics.accessibilityStatus, "Granted")
        XCTAssertEqual(presentation.diagnostics.lastEventText, "12s ago")
        XCTAssertEqual(presentation.diagnostics.lastJumpError, "No matching window")
    }

    private func makeDiagnostics() -> DiagnosticsSnapshot {
        DiagnosticsSnapshot(
            transportStatus: "Listening on 127.0.0.1:48127",
            bridgeStatus: "~/.config/vigil/bridge.json",
            accessibilityStatus: "Granted",
            lastEventText: "5s ago",
            lastJumpError: nil
        )
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
