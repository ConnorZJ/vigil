struct PopoverSummaryPresentation: Equatable {
    let primaryStateLabel: String
    let trackedSessionCount: Int
    let attentionRequiredCount: Int
}

struct PopoverSessionCardPresentation: Equatable {
    let sessionId: String
    let title: String
    let projectName: String
    let relativeUpdatedText: String
    let statusBadgeText: String
    let iconState: MenuBarIconState
    let primaryActionSessionId: String
    let bindActionSessionId: String
}

struct PopoverDiagnosticsPresentation: Equatable {
    let transportStatus: String
    let bridgeStatus: String
    let accessibilityStatus: String
    let lastEventText: String
    let lastTransportError: String?
    let lastJumpError: String?
}

struct PopoverUtilityActionsPresentation: Equatable {
    let showsRefresh: Bool
    let showsAccessibilityRequest: Bool
    let showsQuit: Bool
}

struct PopoverSectionPresentation: Equatable {
    enum Kind: Equatable {
        case summary
        case needsAttention
        case running
        case recentlyCompleted
        case diagnostics
        case utilityActions
    }

    let kind: Kind
    let title: String
    let sessionCards: [PopoverSessionCardPresentation]
}

struct PopoverPresentation: Equatable {
    let summary: PopoverSummaryPresentation
    let diagnostics: PopoverDiagnosticsPresentation
    let utilityActions: PopoverUtilityActionsPresentation
    let sections: [PopoverSectionPresentation]
}
