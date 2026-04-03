import Foundation

struct PopoverPresentationBuilder {
    func build(
        from snapshots: [SessionSnapshot],
        diagnostics: DiagnosticsSnapshot,
        now: Date = Date()
    ) -> PopoverPresentation {
        let sorted = snapshots.sorted { lhs, rhs in
            let left = SessionPriority(status: lhs.status, isStale: lhs.isStale).value
            let right = SessionPriority(status: rhs.status, isStale: rhs.isStale).value

            if left != right {
                return left > right
            }

            return lhs.updatedAt > rhs.updatedAt
        }

        let summary = PopoverSummaryPresentation(
            primaryStateLabel: sorted.first.map(primaryStateLabel(for:)) ?? "Idle",
            trackedSessionCount: snapshots.count,
            attentionRequiredCount: snapshots.filter { $0.status.requiresAttention }.count
        )

        let diagnosticsPresentation = PopoverDiagnosticsPresentation(
            transportStatus: diagnostics.transportStatus,
            bridgeStatus: diagnostics.bridgeStatus,
            accessibilityStatus: diagnostics.accessibilityStatus,
            lastEventText: diagnostics.lastEventText,
            lastTransportError: diagnostics.lastTransportError,
            lastJumpError: diagnostics.lastJumpError
        )

        let utilityActions = PopoverUtilityActionsPresentation(
            showsRefresh: true,
            showsAccessibilityRequest: true,
            showsQuit: true
        )

        var sections: [PopoverSectionPresentation] = [
            PopoverSectionPresentation(kind: .summary, title: "Summary", sessionCards: [])
        ]

        let attention = sorted.filter { $0.status.requiresAttention }
        if !attention.isEmpty {
            sections.append(makeSection(kind: .needsAttention, title: "Needs Attention", snapshots: attention, now: now))
        }

        let running = sorted.filter { $0.status == .running }
        if !running.isEmpty {
            sections.append(makeSection(kind: .running, title: "Running", snapshots: running, now: now))
        }

        let completed = sorted.filter { $0.status == .complete }
        if !completed.isEmpty {
            sections.append(makeSection(kind: .recentlyCompleted, title: "Recently Completed", snapshots: completed, now: now))
        }

        sections.append(PopoverSectionPresentation(kind: .diagnostics, title: "Diagnostics", sessionCards: []))
        sections.append(PopoverSectionPresentation(kind: .utilityActions, title: "Actions", sessionCards: []))

        return PopoverPresentation(
            summary: summary,
            diagnostics: diagnosticsPresentation,
            utilityActions: utilityActions,
            sections: sections
        )
    }

    private func makeSection(kind: PopoverSectionPresentation.Kind, title: String, snapshots: [SessionSnapshot], now: Date) -> PopoverSectionPresentation {
        PopoverSectionPresentation(
            kind: kind,
            title: title,
            sessionCards: snapshots.map { snapshot in
                PopoverSessionCardPresentation(
                    sessionId: snapshot.sessionId,
                    title: snapshot.sessionTitle,
                    projectName: snapshot.projectName,
                    relativeUpdatedText: relativeAgeText(updatedAt: snapshot.updatedAt, now: now),
                    statusBadgeText: statusBadgeText(for: snapshot.status),
                    iconState: iconState(for: snapshot),
                    primaryActionSessionId: snapshot.sessionId,
                    bindActionSessionId: snapshot.sessionId
                )
            }
        )
    }

    private func primaryStateLabel(for snapshot: SessionSnapshot) -> String {
        statusBadgeText(for: snapshot.status)
    }

    private func iconState(for snapshot: SessionSnapshot) -> MenuBarIconState {
        switch snapshot.status {
        case .running:
            return .running
        case .waitingInput:
            return .waitingInput
        case .permission:
            return .permission
        case .complete:
            return .complete
        case .error:
            return .error
        case .unknown:
            return .idle
        }
    }

    private func statusBadgeText(for status: SessionStatus) -> String {
        switch status {
        case .running:
            return "Running"
        case .waitingInput:
            return "Waiting for Input"
        case .permission:
            return "Permission Needed"
        case .complete:
            return "Completed"
        case .error:
            return "Error"
        case .unknown:
            return "Idle"
        }
    }

    private func relativeAgeText(updatedAt: Date, now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(updatedAt)))
        if seconds < 60 {
            return "\(seconds)s ago"
        }

        return "\(seconds / 60)m ago"
    }
}
