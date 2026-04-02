import AppKit
import SwiftUI

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

final class StatusItemPopoverController {
    private let popover: NSPopover
    private let rootViewProvider: () -> AnyView
    private(set) var visibility: PopoverVisibility = .closed

    init(rootViewProvider: @escaping () -> AnyView) {
        self.rootViewProvider = rootViewProvider
        self.popover = NSPopover()
        popover.behavior = .transient
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
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
    }
}
