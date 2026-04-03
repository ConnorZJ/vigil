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

protocol PopoverClickEventMonitoring {
    func addLocalMouseDownMonitor(handler: @escaping (Int) -> Void) -> Any
    func addGlobalMouseDownMonitor(handler: @escaping () -> Void) -> Any
    func removeMonitor(_ monitor: Any)
}

struct AppKitPopoverClickEventMonitor: PopoverClickEventMonitoring {
    func addLocalMouseDownMonitor(handler: @escaping (Int) -> Void) -> Any {
        let monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { event in
            handler(event.windowNumber)
            return event
        }

        return monitor as Any
    }

    func addGlobalMouseDownMonitor(handler: @escaping () -> Void) -> Any {
        let monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { _ in
            handler()
        }

        return monitor as Any
    }

    func removeMonitor(_ monitor: Any) {
        NSEvent.removeMonitor(monitor)
    }
}

enum PopoverOutsideClickDecision {
    static func shouldCloseLocalClick(eventWindowNumber: Int, popoverWindowNumber: Int?, buttonWindowNumber: Int?) -> Bool {
        if let popoverWindowNumber, eventWindowNumber == popoverWindowNumber {
            return false
        }

        if let buttonWindowNumber, eventWindowNumber == buttonWindowNumber {
            return false
        }

        return true
    }
}

final class PopoverDismissMonitor {
    private let eventMonitor: PopoverClickEventMonitoring
    private let onOutsideClick: () -> Void
    private var localMonitor: Any?
    private var globalMonitor: Any?

    init(eventMonitor: PopoverClickEventMonitoring, onOutsideClick: @escaping () -> Void) {
        self.eventMonitor = eventMonitor
        self.onOutsideClick = onOutsideClick
    }

    func start(popoverWindowNumber: Int?, buttonWindowNumber: Int?) {
        stop()

        localMonitor = eventMonitor.addLocalMouseDownMonitor { [weak self] eventWindowNumber in
            guard let self else { return }

            if PopoverOutsideClickDecision.shouldCloseLocalClick(
                eventWindowNumber: eventWindowNumber,
                popoverWindowNumber: popoverWindowNumber,
                buttonWindowNumber: buttonWindowNumber
            ) {
                self.onOutsideClick()
            }
        }

        globalMonitor = eventMonitor.addGlobalMouseDownMonitor { [weak self] in
            self?.onOutsideClick()
        }
    }

    func stop() {
        if let localMonitor {
            eventMonitor.removeMonitor(localMonitor)
            self.localMonitor = nil
        }

        if let globalMonitor {
            eventMonitor.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }
}

final class StatusItemPopoverController: NSObject, NSPopoverDelegate {
    private let popover: NSPopover
    private let eventMonitor: PopoverClickEventMonitoring
    private lazy var dismissMonitor = PopoverDismissMonitor(eventMonitor: eventMonitor) { [weak self] in
        self?.close()
    }
    var rootViewProvider: () -> AnyView
    private(set) var visibility: PopoverVisibility = .closed

    init(rootViewProvider: @escaping () -> AnyView, eventMonitor: PopoverClickEventMonitoring = AppKitPopoverClickEventMonitor()) {
        self.rootViewProvider = rootViewProvider
        self.popover = NSPopover()
        self.eventMonitor = eventMonitor
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
        dismissMonitor.stop()
        popover.performClose(nil)
        visibility = .closed
    }

    private func show(relativeTo button: NSStatusBarButton) {
        popover.contentViewController = NSHostingController(rootView: rootViewProvider())
        popover.contentSize = NSSize(width: 360, height: 420)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
        dismissMonitor.start(
            popoverWindowNumber: popover.contentViewController?.view.window?.windowNumber,
            buttonWindowNumber: button.window?.windowNumber
        )
    }

    func popoverDidClose(_ notification: Notification) {
        dismissMonitor.stop()
        visibility = .closed
    }
}
