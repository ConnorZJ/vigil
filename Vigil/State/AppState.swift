import Foundation

struct DiagnosticsSnapshot: Equatable {
    let transportStatus: String
    let bridgeStatus: String
    let accessibilityStatus: String
    let lastEventText: String
    let lastTransportError: String?
    let lastJumpError: String?
}

final class AppState {
    private let clock: TimeProviding
    private let sessionStore: SessionStore
    private let sessionPersistence: SessionSnapshotLoading
    private let transportServer: TransportServing
    private let permissionService: AXPermissionProviding
    private let ghosttyWindowQueryService: GhosttyWindowQuerying
    private let ghosttyWindowBinder: GhosttyWindowBinder
    private let ghosttyWindowActivator: GhosttyWindowActivating
    private let housekeepingScheduler: RepeatingTaskScheduling
    private let housekeepingInterval: TimeInterval
    private let paths: Paths

    private var lastJumpError: String?
    private var housekeepingTask: RepeatingTask?

    var onChange: (() -> Void)?

    init(
        clock: TimeProviding = SystemTimeProvider(),
        sessionStore: SessionStore = SessionStore(),
        sessionPersistence: SessionSnapshotLoading? = nil,
        transportServer: TransportServing? = nil,
        permissionService: AXPermissionProviding = AXPermissionService(),
        ghosttyWindowQueryService: GhosttyWindowQuerying = GhosttyAXWindowQueryService(),
        ghosttyWindowBinder: GhosttyWindowBinder? = nil,
        ghosttyWindowActivator: GhosttyWindowActivating? = nil,
        paths: Paths = Paths(),
        housekeepingScheduler: RepeatingTaskScheduling = TimerRepeatingTaskScheduler(),
        housekeepingInterval: TimeInterval = 30
    ) {
        self.clock = clock
        self.sessionStore = sessionStore
        self.sessionPersistence = sessionPersistence ?? SessionPersistence(paths: paths)
        self.transportServer = transportServer ?? EmbeddedHTTPServer(sessionStore: sessionStore)
        self.permissionService = permissionService
        self.ghosttyWindowQueryService = ghosttyWindowQueryService
        let binder = ghosttyWindowBinder ?? GhosttyWindowBinder(persistence: BindingPersistence(), clock: clock)
        self.ghosttyWindowBinder = binder
        self.paths = paths
        self.housekeepingScheduler = housekeepingScheduler
        self.housekeepingInterval = housekeepingInterval
        self.ghosttyWindowActivator = ghosttyWindowActivator ?? GhosttyWindowActivator(
            queryService: ghosttyWindowQueryService,
            matcher: GhosttyWindowMatcher(),
            binder: binder,
            permissionService: permissionService
        )
        self.transportServer.onStateChange = { [weak self] in
            guard let self else {
                return
            }

            if Thread.isMainThread {
                self.onChange?()
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.onChange?()
                }
            }
        }
    }

    deinit {
        housekeepingTask?.cancel()
    }

    var presentation: SessionMenuPresentation {
        refreshSessionState()
        return SessionMenuBuilder().build(from: sessionStore.allSnapshots, now: clock.now)
    }

    var sessionSnapshots: [SessionSnapshot] {
        refreshSessionState()
        return sessionStore.allSnapshots
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
        let bridgeStatus: String
        if transportServer.bridgeWriteSucceeded {
            bridgeStatus = "Bridge written: \(paths.bridgeFile.path)"
        } else {
            bridgeStatus = "Bridge write failed"
        }

        let lastTransportError: String? = if let stage = transportServer.lastErrorStage, let message = transportServer.lastErrorMessage {
            "\(stage.rawValue): \(message)"
        } else {
            nil
        }

        return DiagnosticsSnapshot(
            transportStatus: transportServer.isListening ? "Listening on 127.0.0.1:\(transportServer.port ?? 0)" : "Offline",
            bridgeStatus: bridgeStatus,
            accessibilityStatus: accessibilityPermissionStatus == .granted ? "Granted" : "Not granted",
            lastEventText: transportServer.lastReceivedEventAt.map { relativeTimestampText(from: $0) } ?? "No events received",
            lastTransportError: lastTransportError,
            lastJumpError: lastJumpError
        )
    }

    func currentGhosttyWindows() -> [GhosttyWindowDescriptor] {
        (try? ghosttyWindowQueryService.currentWindows()) ?? []
    }

    @discardableResult
    func openSession(sessionId: String) -> Bool {
        guard let snapshot = sessionStore.snapshot(for: sessionId) else {
            return false
        }

        do {
            try ghosttyWindowActivator.activateBestWindow(for: snapshot)
            lastJumpError = nil
            onChange?()
            return true
        } catch {
            lastJumpError = error.localizedDescription
            Logger.shared.log("Failed to activate Ghostty window: \(error.localizedDescription)")
            onChange?()
            return false
        }
    }

    @discardableResult
    func bindFrontmostWindow(sessionId: String) -> Bool {
        do {
            try ghosttyWindowActivator.bindFrontmostWindow(to: sessionId)
            lastJumpError = nil
            onChange?()
            return true
        } catch {
            lastJumpError = error.localizedDescription
            Logger.shared.log("Failed to bind Ghostty window: \(error.localizedDescription)")
            onChange?()
            return false
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
            let restoredSnapshots = try sessionPersistence.load(now: clock.now)
            for snapshot in restoredSnapshots {
                sessionStore.restore(snapshot: snapshot)
            }
            refreshSessionState()
        } catch {
            Logger.shared.log("Failed to restore persisted sessions: \(error.localizedDescription)")
        }

        do {
            try transportServer.start(port: 48127)
        } catch {
            Logger.shared.log("Failed to start transport: \(error.localizedDescription)")
        }

        if seedPreviewData && transportServer.lastReceivedEventAt == nil {
            seedPreviewSessions()
        }

        startAutomaticHousekeeping()
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

    @discardableResult
    private func refreshSessionState(now: Date? = nil) -> Bool {
        let previousSnapshots = sessionStore.allSnapshots
        let current = now ?? clock.now
        sessionStore.markStaleSessions(now: current)
        sessionStore.applyRetentionPolicy(now: current)
        return previousSnapshots != sessionStore.allSnapshots
    }

    private func startAutomaticHousekeeping() {
        housekeepingTask?.cancel()
        housekeepingTask = housekeepingScheduler.scheduleRepeating(every: housekeepingInterval) { [weak self] in
            guard let self else {
                return
            }

            if self.refreshSessionState() {
                self.onChange?()
            }
        }
    }
}
