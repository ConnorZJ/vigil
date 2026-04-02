import Foundation

struct DiagnosticsSnapshot: Equatable {
    let transportStatus: String
    let bridgeStatus: String
    let accessibilityStatus: String
    let lastEventText: String
    let lastJumpError: String?
}

final class AppState {
    private let clock: TimeProviding
    private let menuBuilder: SessionMenuBuilder
    private let sessionStore: SessionStore
    private let transportServer: EmbeddedHTTPServer
    private let permissionService: AXPermissionProviding
    private let ghosttyWindowQueryService: GhosttyWindowQuerying
    private let ghosttyWindowBinder: GhosttyWindowBinder
    private let ghosttyWindowActivator: GhosttyWindowActivating
    private let paths: Paths

    private var lastJumpError: String?

    var onChange: (() -> Void)?

    init(
        clock: TimeProviding = SystemTimeProvider(),
        menuBuilder: SessionMenuBuilder = SessionMenuBuilder(),
        sessionStore: SessionStore = SessionStore(),
        transportServer: EmbeddedHTTPServer? = nil,
        permissionService: AXPermissionProviding = AXPermissionService(),
        ghosttyWindowQueryService: GhosttyWindowQuerying = GhosttyAXWindowQueryService(),
        ghosttyWindowBinder: GhosttyWindowBinder? = nil,
        ghosttyWindowActivator: GhosttyWindowActivating? = nil,
        paths: Paths = Paths()
    ) {
        self.clock = clock
        self.menuBuilder = menuBuilder
        self.sessionStore = sessionStore
        self.transportServer = transportServer ?? EmbeddedHTTPServer(sessionStore: sessionStore)
        self.permissionService = permissionService
        self.ghosttyWindowQueryService = ghosttyWindowQueryService
        let binder = ghosttyWindowBinder ?? GhosttyWindowBinder(persistence: BindingPersistence(), clock: clock)
        self.ghosttyWindowBinder = binder
        self.paths = paths
        self.ghosttyWindowActivator = ghosttyWindowActivator ?? GhosttyWindowActivator(
            queryService: ghosttyWindowQueryService,
            matcher: GhosttyWindowMatcher(),
            binder: binder,
            permissionService: permissionService
        )
    }

    var presentation: SessionMenuPresentation {
        menuBuilder.build(from: sessionStore.allSnapshots, now: clock.now)
    }

    var menuActions: SessionMenuActions {
        SessionMenuActions(
            openSession: { [weak self] sessionId in
                self?.openSession(sessionId: sessionId)
            },
            bindFrontmostWindow: { [weak self] sessionId in
                self?.bindFrontmostWindow(sessionId: sessionId)
            },
            refreshMappings: { [weak self] in
                self?.refreshMappings()
            },
            openSettings: { [weak self] in
                self?.requestAccessibilityPermission()
            }
        )
    }

    var accessibilityPermissionStatus: AXPermissionStatus {
        permissionService.status
    }

    var diagnosticsSnapshot: DiagnosticsSnapshot {
        let fileManager = FileManager.default
        let bridgeExists = fileManager.fileExists(atPath: paths.bridgeFile.path)
        let lastEvent = sessionStore.allSnapshots.map(\.updatedAt).max()

        return DiagnosticsSnapshot(
            transportStatus: transportServer.port.map { "Listening on 127.0.0.1:\($0)" } ?? "Offline",
            bridgeStatus: bridgeExists ? paths.bridgeFile.path : "Missing bridge file",
            accessibilityStatus: accessibilityPermissionStatus == .granted ? "Granted" : "Not granted",
            lastEventText: lastEvent.map { relativeTimestampText(from: $0) } ?? "No events received",
            lastJumpError: lastJumpError
        )
    }

    func currentGhosttyWindows() -> [GhosttyWindowDescriptor] {
        (try? ghosttyWindowQueryService.currentWindows()) ?? []
    }

    func openSession(sessionId: String) {
        guard let snapshot = sessionStore.snapshot(for: sessionId) else {
            return
        }

        do {
            try ghosttyWindowActivator.activateBestWindow(for: snapshot)
            lastJumpError = nil
        } catch {
            lastJumpError = error.localizedDescription
            Logger.shared.log("Failed to activate Ghostty window: \(error.localizedDescription)")
        }

        onChange?()
    }

    func bindFrontmostWindow(sessionId: String) {
        do {
            try ghosttyWindowActivator.bindFrontmostWindow(to: sessionId)
            lastJumpError = nil
            onChange?()
        } catch {
            lastJumpError = error.localizedDescription
            Logger.shared.log("Failed to bind Ghostty window: \(error.localizedDescription)")
        }
    }

    func refreshMappings() {
        onChange?()
    }

    func requestAccessibilityPermission() {
        permissionService.requestAccessPrompt()
        onChange?()
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

    private func relativeTimestampText(from date: Date) -> String {
        let seconds = max(0, Int(clock.now.timeIntervalSince(date)))
        if seconds < 60 {
            return "\(seconds)s ago"
        }

        let minutes = seconds / 60
        return "\(minutes)m ago"
    }
}
