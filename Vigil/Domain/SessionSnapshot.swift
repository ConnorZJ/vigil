import Foundation

struct SessionSnapshot: Codable, Equatable {
    struct WindowHint: Codable, Equatable {
        let cwd: String?
        let tabTitle: String?
        let tty: String?

        init(cwd: String? = nil, tabTitle: String? = nil, tty: String? = nil) {
            self.cwd = cwd
            self.tabTitle = tabTitle
            self.tty = tty
        }
    }

    let sessionId: String
    let sessionTitle: String
    let projectPath: String
    let projectName: String
    let terminalApp: String
    let status: SessionStatus
    let updatedAt: Date
    let windowHint: WindowHint?
    let workspaceHint: String?
    let lastError: String?
    let requiresAttentionReason: String?
    let isStale: Bool

    init(
        sessionId: String,
        sessionTitle: String,
        projectPath: String,
        projectName: String,
        terminalApp: String,
        status: SessionStatus,
        updatedAt: Date,
        windowHint: WindowHint? = nil,
        workspaceHint: String? = nil,
        lastError: String? = nil,
        requiresAttentionReason: String? = nil,
        isStale: Bool = false
    ) {
        self.sessionId = sessionId
        self.sessionTitle = sessionTitle
        self.projectPath = projectPath
        self.projectName = projectName
        self.terminalApp = terminalApp
        self.status = status
        self.updatedAt = updatedAt
        self.windowHint = windowHint
        self.workspaceHint = workspaceHint
        self.lastError = lastError
        self.requiresAttentionReason = requiresAttentionReason
        self.isStale = isStale
    }
}
