import CoreGraphics
import Foundation
import XCTest
@testable import Vigil

final class GhosttyWindowMatcherTests: XCTestCase {
    func testExactProjectNameMatchBeatsLooseSubstringMatch() {
        let matcher = GhosttyWindowMatcher()
        let snapshot = makeSnapshot(projectName: "vigil")
        let windows = [
            GhosttyWindowDescriptor(title: "some-vigil-notes", frame: .zero, isFocused: false),
            GhosttyWindowDescriptor(title: "vigil", frame: .zero, isFocused: false)
        ]

        let match = matcher.bestMatch(for: snapshot, among: windows, persistedSignature: nil)
        XCTAssertEqual(match?.title, "vigil")
    }

    func testCwdHintBeatsTitleOnlyFuzzyMatch() {
        let matcher = GhosttyWindowMatcher()
        let snapshot = makeSnapshot(projectName: "vigil", cwd: "/tmp/right")
        let windows = [
            GhosttyWindowDescriptor(title: "vigil", frame: .zero, isFocused: false, cwd: "/tmp/wrong"),
            GhosttyWindowDescriptor(title: "terminal", frame: .zero, isFocused: false, cwd: "/tmp/right")
        ]

        let match = matcher.bestMatch(for: snapshot, among: windows, persistedSignature: nil)
        XCTAssertEqual(match?.cwd, "/tmp/right")
    }

    func testTabTitleAndTtyHintsImproveScore() {
        let matcher = GhosttyWindowMatcher()
        let snapshot = makeSnapshot(projectName: "vigil", tabTitle: "agent", tty: "/dev/ttys001")
        let windows = [
            GhosttyWindowDescriptor(title: "vigil", frame: .zero, isFocused: false, tabTitle: nil, tty: nil),
            GhosttyWindowDescriptor(title: "vigil", frame: .zero, isFocused: false, tabTitle: "agent", tty: "/dev/ttys001")
        ]

        let match = matcher.bestMatch(for: snapshot, among: windows, persistedSignature: nil)
        XCTAssertEqual(match?.tty, "/dev/ttys001")
    }

    func testPersistedWindowSignatureImprovesMatchConfidence() {
        let matcher = GhosttyWindowMatcher()
        let snapshot = makeSnapshot(projectName: "vigil")
        let signature = WindowSignature(
            title: "vigil",
            frame: CGRectCodable(x: 400, y: 400, width: 900, height: 700),
            observedAt: FixedClock().now,
            cwd: nil,
            tabTitle: nil,
            tty: nil
        )
        let windows = [
            GhosttyWindowDescriptor(title: "vigil", frame: CGRect(x: 0, y: 0, width: 900, height: 700), isFocused: false),
            GhosttyWindowDescriptor(title: "vigil", frame: CGRect(x: 402, y: 398, width: 900, height: 700), isFocused: false)
        ]

        let match = matcher.bestMatch(for: snapshot, among: windows, persistedSignature: signature)
        XCTAssertEqual(match?.frame.origin.x, 402)
    }

    func testPersistedTabSignatureBeatsCompetingWindowWithSameFrame() {
        let matcher = GhosttyWindowMatcher()
        let snapshot = makeSnapshot(projectName: "vigil")
        let signature = WindowSignature(
            title: "vigil",
            frame: CGRectCodable(x: 400, y: 400, width: 900, height: 700),
            observedAt: FixedClock().now,
            cwd: "/tmp/vigil",
            tabTitle: "agent-2",
            tty: "/dev/ttys009"
        )
        let windows = [
            GhosttyWindowDescriptor(
                title: "vigil",
                frame: CGRect(x: 400, y: 400, width: 900, height: 700),
                isFocused: false,
                cwd: "/tmp/vigil",
                tabTitle: "agent-1",
                tty: "/dev/ttys001"
            ),
            GhosttyWindowDescriptor(
                title: "vigil",
                frame: CGRect(x: 400, y: 400, width: 900, height: 700),
                isFocused: false,
                cwd: "/tmp/vigil",
                tabTitle: "agent-2",
                tty: "/dev/ttys009"
            )
        ]

        let match = matcher.bestMatch(for: snapshot, among: windows, persistedSignature: signature)
        XCTAssertEqual(match?.tabTitle, "agent-2")
    }

    func testActivatorDescriptorIdentityRequiresTabMatchWhenTargetHasTabMetadata() {
        let target = GhosttyWindowDescriptor(
            title: "vigil",
            frame: CGRect(x: 100, y: 100, width: 800, height: 600),
            isFocused: false,
            cwd: "/tmp/vigil",
            tabTitle: "agent-2",
            tty: "/dev/ttys009"
        )
        let wrongTab = GhosttyWindowDescriptor(
            title: "vigil",
            frame: CGRect(x: 100, y: 100, width: 800, height: 600),
            isFocused: false,
            cwd: "/tmp/vigil",
            tabTitle: "agent-1",
            tty: "/dev/ttys001"
        )
        let matchingTab = GhosttyWindowDescriptor(
            title: "vigil",
            frame: CGRect(x: 100, y: 100, width: 800, height: 600),
            isFocused: false,
            cwd: "/tmp/vigil",
            tabTitle: "agent-2",
            tty: "/dev/ttys009"
        )

        XCTAssertFalse(GhosttyWindowActivator.descriptorMatches(wrongTab, target: target))
        XCTAssertTrue(GhosttyWindowActivator.descriptorMatches(matchingTab, target: target))
    }

    func testActivatorDescriptorIdentityFallsBackToTitleAndFrameWhenTabMetadataAbsent() {
        let target = GhosttyWindowDescriptor(
            title: "vigil",
            frame: CGRect(x: 100, y: 100, width: 800, height: 600),
            isFocused: false
        )
        let matchingWindow = GhosttyWindowDescriptor(
            title: "vigil",
            frame: CGRect(x: 102, y: 98, width: 800, height: 600),
            isFocused: false
        )

        XCTAssertTrue(GhosttyWindowActivator.descriptorMatches(matchingWindow, target: target))
    }

    func testMissingSignatureFallsBackToFuzzyMatch() {
        let matcher = GhosttyWindowMatcher()
        let snapshot = makeSnapshot(projectName: "vigil")
        let windows = [GhosttyWindowDescriptor(title: "vigil", frame: .zero, isFocused: false)]

        let match = matcher.bestMatch(for: snapshot, among: windows, persistedSignature: nil)
        XCTAssertEqual(match?.title, "vigil")
    }

    private func makeSnapshot(projectName: String, cwd: String? = nil, tabTitle: String? = nil, tty: String? = nil) -> SessionSnapshot {
        SessionSnapshot(
            sessionId: "session-1",
            sessionTitle: "refactor auth middleware",
            projectPath: "/tmp/\(projectName)",
            projectName: projectName,
            terminalApp: "ghostty",
            status: .running,
            updatedAt: FixedClock().now,
            windowHint: .init(cwd: cwd, tabTitle: tabTitle, tty: tty)
        )
    }
}
