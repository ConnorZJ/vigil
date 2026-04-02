import Foundation

final class AppState {
    private let clock: TimeProviding
    private let menuBuilder: SessionMenuBuilder
    private let sessionStore: SessionStore
    private let transportServer: EmbeddedHTTPServer
    private let permissionService: AXPermissionProviding
    private let ghosttyWindowQueryService: GhosttyWindowQuerying

    var onChange: (() -> Void)?

    init(
        clock: TimeProviding = SystemTimeProvider(),
        menuBuilder: SessionMenuBuilder = SessionMenuBuilder(),
        sessionStore: SessionStore = SessionStore(),
        transportServer: EmbeddedHTTPServer? = nil,
        permissionService: AXPermissionProviding = AXPermissionService(),
        ghosttyWindowQueryService: GhosttyWindowQuerying = GhosttyAXWindowQueryService()
    ) {
        self.clock = clock
        self.menuBuilder = menuBuilder
        self.sessionStore = sessionStore
        self.transportServer = transportServer ?? EmbeddedHTTPServer(sessionStore: sessionStore)
        self.permissionService = permissionService
        self.ghosttyWindowQueryService = ghosttyWindowQueryService
    }

    var presentation: SessionMenuPresentation {
        menuBuilder.build(from: sessionStore.allSnapshots, now: clock.now)
    }

    var menuActions: SessionMenuActions {
        .noop
    }

    var accessibilityPermissionStatus: AXPermissionStatus {
        permissionService.status
    }

    func currentGhosttyWindows() -> [GhosttyWindowDescriptor] {
        (try? ghosttyWindowQueryService.currentWindows()) ?? []
    }

    func bootstrap(seedPreviewData: Bool = false) {
        do {
            try transportServer.start()
        } catch {
            Logger.shared.log("Failed to start transport: \(error.localizedDescription)")
        }

        if seedPreviewData {
            seedPreviewSessions()
        }

        onChange?()
    }

    func seedPreviewSessions() {
        let now = clock.now
        let previewSnapshots = [
            makePreviewSnapshot(id: "waiting", status: .waitingInput, updatedAt: now.addingTimeInterval(-15)),
            makePreviewSnapshot(id: "running", status: .running, updatedAt: now.addingTimeInterval(-45)),
            makePreviewSnapshot(id: "complete", status: .complete, updatedAt: now.addingTimeInterval(-120))
        ]

        for snapshot in previewSnapshots {
            sessionStore.apply(
                event: SessionEvent(
                    eventId: UUID().uuidString,
                    eventType: eventType(for: snapshot.status),
                    sentAt: snapshot.updatedAt,
                    session: snapshot
                )
            )
        }

        onChange?()
    }

    private func makePreviewSnapshot(id: String, status: SessionStatus, updatedAt: Date) -> SessionSnapshot {
        SessionSnapshot(
            sessionId: id,
            sessionTitle: "Preview \(id.capitalized)",
            projectPath: "/tmp/\(id)",
            projectName: "preview-\(id)",
            terminalApp: "ghostty",
            status: status,
            updatedAt: updatedAt,
            requiresAttentionReason: status.requiresAttention ? "Preview attention state" : nil
        )
    }

    private func eventType(for status: SessionStatus) -> String {
        switch status {
        case .waitingInput:
            return "session.waiting_input"
        case .permission:
            return "session.permission_requested"
        case .complete:
            return "session.completed"
        case .error:
            return "session.failed"
        case .running, .unknown:
            return "session.updated"
        }
    }
}
