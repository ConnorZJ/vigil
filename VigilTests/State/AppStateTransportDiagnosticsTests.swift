import Foundation
import XCTest
@testable import Vigil

final class AppStateTransportDiagnosticsTests: XCTestCase {
    func testDiagnosticsExposeTransportFacts() {
        let now = Date(timeIntervalSince1970: 1_712_000_000)
        let transport = FakeTransportServer(
            port: 48127,
            token: "secret",
            isListening: true,
            bridgeWriteSucceeded: true,
            lastErrorStage: .auth,
            lastErrorMessage: "bad token",
            lastReceivedEventAt: now.addingTimeInterval(-5)
        )

        let appState = AppState(
            clock: FixedClock(now: now),
            sessionStore: SessionStore(clock: FixedClock(now: now)),
            transportServer: transport,
            permissionService: FakePermissionService(status: .granted),
            ghosttyWindowQueryService: FakeGhosttyWindowQueryService(),
            ghosttyWindowBinder: GhosttyWindowBinder(persistence: InMemoryBindingPersistence(), clock: FixedClock(now: now)),
            ghosttyWindowActivator: FakeGhosttyWindowActivator(),
            paths: Paths(rootURL: temporaryDirectory())
        )

        let diagnostics = appState.diagnosticsSnapshot

        XCTAssertTrue(diagnostics.transportStatus.contains("48127"))
        XCTAssertTrue(diagnostics.bridgeStatus.contains("written"))
        XCTAssertEqual(diagnostics.lastEventText, "5s ago")
        XCTAssertEqual(diagnostics.lastTransportError, "auth: bad token")
    }
}

private struct FakeTransportServer: TransportServing {
    let port: Int?
    let token: String?
    let isListening: Bool
    let bridgeWriteSucceeded: Bool
    let lastErrorStage: TransportErrorStage?
    let lastErrorMessage: String?
    let lastReceivedEventAt: Date?

    func start(port: Int) throws {}
    func stop() {}
}

private struct FakePermissionService: AXPermissionProviding {
    let status: AXPermissionStatus
    func requestAccessPrompt() {}
}

private struct FakeGhosttyWindowQueryService: GhosttyWindowQuerying {
    func currentWindows() throws -> [GhosttyWindowDescriptor] { [] }
    func frontmostWindow() throws -> GhosttyWindowDescriptor? { nil }
}

private struct InMemoryBindingPersistence: BindingPersisting {
    func load() throws -> [String: WindowSignature] { [:] }
    func save(_ bindings: [String: WindowSignature]) throws {}
}

private struct FakeGhosttyWindowActivator: GhosttyWindowActivating {
    func activateBestWindow(for snapshot: SessionSnapshot) throws {}
    func bindFrontmostWindow(to sessionId: String) throws {}
}
