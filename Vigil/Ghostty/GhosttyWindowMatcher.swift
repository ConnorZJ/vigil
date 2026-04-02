import CoreGraphics
import Foundation

struct GhosttyWindowMatcher {
    func bestMatch(
        for snapshot: SessionSnapshot,
        among windows: [GhosttyWindowDescriptor],
        persistedSignature: WindowSignature?
    ) -> GhosttyWindowDescriptor? {
        windows.max { lhs, rhs in
            score(for: lhs, snapshot: snapshot, signature: persistedSignature) < score(for: rhs, snapshot: snapshot, signature: persistedSignature)
        }
    }

    private func score(for window: GhosttyWindowDescriptor, snapshot: SessionSnapshot, signature: WindowSignature?) -> Int {
        var score = 0
        let normalizedTitle = window.title.lowercased()
        let projectName = snapshot.projectName.lowercased()
        let sessionTitle = snapshot.sessionTitle.lowercased()

        if normalizedTitle == projectName {
            score += 100
        } else if normalizedTitle.contains(projectName) {
            score += 50
        }

        if normalizedTitle.contains(sessionTitle) {
            score += 30
        }

        if let cwd = snapshot.windowHint?.cwd, window.cwd == cwd {
            score += 120
        }

        if let tabTitle = snapshot.windowHint?.tabTitle, window.tabTitle == tabTitle {
            score += 90
        }

        if let tty = snapshot.windowHint?.tty, window.tty == tty {
            score += 40
        }

        if let signature {
            if signature.title == window.title {
                score += 25
            }

            let signatureRect = CGRect(
                x: signature.frame.x,
                y: signature.frame.y,
                width: signature.frame.width,
                height: signature.frame.height
            )
            if frameDistance(between: signatureRect, and: window.frame) < 20 {
                score += 35
            }
        }

        if window.isFocused {
            score += 5
        }

        return score
    }

    private func frameDistance(between lhs: CGRect, and rhs: CGRect) -> CGFloat {
        abs(lhs.origin.x - rhs.origin.x) + abs(lhs.origin.y - rhs.origin.y) + abs(lhs.width - rhs.width) + abs(lhs.height - rhs.height)
    }
}
