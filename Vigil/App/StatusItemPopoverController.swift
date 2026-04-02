import AppKit
import SwiftUI

enum PopoverActionKind {
    case jump
    case bind
    case refresh
    case accessibility
}

enum PopoverDismissPolicy {
    static func shouldClose(for action: PopoverActionKind, succeeded: Bool) -> Bool {
        switch action {
        case .jump:
            return succeeded
        case .bind, .refresh, .accessibility:
            return false
        }
    }
}

enum PopoverVisibility: Equatable {
    case closed
    case open

    mutating func toggle() {
        switch self {
        case .closed:
            self = .open
        case .open:
            self = .closed
        }
    }
}

final class StatusItemPopoverController: NSObject, NSPopoverDelegate {
    private let popover: NSPopover
    var rootViewProvider: () -> AnyView
    private(set) var visibility: PopoverVisibility = .closed

    init(rootViewProvider: @escaping () -> AnyView) {
        self.rootViewProvider = rootViewProvider
        self.popover = NSPopover()
        super.init()
        popover.behavior = .transient
        popover.delegate = self
    }

    func toggle(relativeTo button: NSStatusBarButton) {
        visibility.toggle()

        switch visibility {
        case .open:
            show(relativeTo: button)
        case .closed:
            close()
        }
    }

    func close() {
        popover.performClose(nil)
        visibility = .closed
    }

    private func show(relativeTo button: NSStatusBarButton) {
        popover.contentViewController = NSHostingController(rootView: rootViewProvider())
        popover.contentSize = NSSize(width: 360, height: 420)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
    }

    func popoverDidClose(_ notification: Notification) {
        visibility = .closed
    }
}
