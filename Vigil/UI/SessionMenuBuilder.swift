import Foundation

enum MenuBarIconState: Equatable {
    case idle
    case running
    case waitingInput
    case permission
    case complete
    case error
}

struct SessionMenuSection: Equatable {
    enum Kind: Equatable {
        case summary
        case needsAttention
        case running
        case recentlyCompleted
    }

    let kind: Kind
    let title: String
    let rows: [SessionMenuRowViewModel]
    let summaryText: String?
}

struct SessionMenuPresentation: Equatable {
    let iconState: MenuBarIconState
    let sections: [SessionMenuSection]
}

struct SessionMenuBuilder {
    func build(from snapshots: [SessionSnapshot], now: Date = Date()) -> SessionMenuPresentation {
        let sorted = snapshots.sorted { lhs, rhs in
            let left = SessionPriority(status: lhs.status, isStale: lhs.isStale).value
            let right = SessionPriority(status: rhs.status, isStale: rhs.isStale).value

            if left != right {
                return left > right
            }

            return lhs.updatedAt > rhs.updatedAt
        }

        let iconState = sorted.first.map(iconState(for:)) ?? .idle
        var sections: [SessionMenuSection] = []

        sections.append(
            SessionMenuSection(
                kind: .summary,
                title: "Summary",
                rows: [],
                summaryText: "\(snapshots.count) tracked, \(snapshots.filter { $0.status.requiresAttention }.count) need attention"
            )
        )

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

        return SessionMenuPresentation(iconState: iconState, sections: sections)
    }

    private func makeSection(kind: SessionMenuSection.Kind, title: String, snapshots: [SessionSnapshot], now: Date) -> SessionMenuSection {
        SessionMenuSection(
            kind: kind,
            title: title,
            rows: snapshots.map { snapshot in
                SessionMenuRowViewModel(
                    sessionId: snapshot.sessionId,
                    title: snapshot.sessionTitle,
                    projectName: snapshot.projectName,
                    iconState: iconState(for: snapshot),
                    statusText: statusText(for: snapshot.status),
                    relativeUpdatedText: relativeAgeText(updatedAt: snapshot.updatedAt, now: now),
                    requiresAttention: snapshot.status.requiresAttention
                )
            },
            summaryText: nil
        )
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

    private func statusText(for status: SessionStatus) -> String {
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
            return "Unknown"
        }
    }

    private func relativeAgeText(updatedAt: Date, now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(updatedAt)))
        if seconds < 60 {
            return "\(seconds)s ago"
        }

        let minutes = seconds / 60
        return "\(minutes)m ago"
    }
}
