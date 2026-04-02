import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

enum GhosttyWindowActivationError: Error {
    case permissionDenied
    case appNotRunning
    case noMatchingWindow
    case noFrontmostWindow
    case activationFailed
}

protocol GhosttyWindowActivating {
    func activateBestWindow(for snapshot: SessionSnapshot) throws
    func bindFrontmostWindow(to sessionId: String) throws
}

final class GhosttyWindowActivator: GhosttyWindowActivating {
    private let queryService: GhosttyWindowQuerying
    private let matcher: GhosttyWindowMatcher
    private let binder: GhosttyWindowBinder
    private let permissionService: AXPermissionProviding
    private let workspace: NSWorkspace

    init(
        queryService: GhosttyWindowQuerying,
        matcher: GhosttyWindowMatcher,
        binder: GhosttyWindowBinder,
        permissionService: AXPermissionProviding,
        workspace: NSWorkspace = .shared
    ) {
        self.queryService = queryService
        self.matcher = matcher
        self.binder = binder
        self.permissionService = permissionService
        self.workspace = workspace
    }

    func activateBestWindow(for snapshot: SessionSnapshot) throws {
        guard permissionService.status == .granted else {
            throw GhosttyWindowActivationError.permissionDenied
        }

        let windows = try queryService.currentWindows()
        guard let match = matcher.bestMatch(for: snapshot, among: windows, persistedSignature: binder.binding(for: snapshot.sessionId)) else {
            throw GhosttyWindowActivationError.noMatchingWindow
        }

        guard let app = ghosttyApp() else {
            throw GhosttyWindowActivationError.appNotRunning
        }

        let activated = app.activate(options: [.activateAllWindows])
        guard activated else {
            throw GhosttyWindowActivationError.activationFailed
        }

        try raiseWindow(matching: match, processIdentifier: app.processIdentifier)
    }

    func bindFrontmostWindow(to sessionId: String) throws {
        guard let window = try queryService.frontmostWindow() else {
            throw GhosttyWindowActivationError.noFrontmostWindow
        }

        try binder.bind(window: window, to: sessionId)
    }

    private func ghosttyApp() -> NSRunningApplication? {
        workspace.runningApplications.first { application in
            application.bundleIdentifier == "com.mitchellh.ghostty" || application.localizedName == "Ghostty"
        }
    }

    private func raiseWindow(matching descriptor: GhosttyWindowDescriptor, processIdentifier: pid_t) throws {
        let appElement = AXUIElementCreateApplication(processIdentifier)
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value)
        guard result == .success, let windows = value as? [AXUIElement] else {
            throw GhosttyWindowActivationError.noMatchingWindow
        }

        for element in windows {
            let title = stringAttribute(kAXTitleAttribute as CFString, from: element) ?? "Ghostty"
            let position = pointAttribute(kAXPositionAttribute as CFString, from: element) ?? .zero
            let size = sizeAttribute(kAXSizeAttribute as CFString, from: element) ?? .zero
            let frame = CGRect(origin: position, size: size)

            if title == descriptor.title, frameDistance(frame, descriptor.frame) < 20 {
                let raiseResult = AXUIElementPerformAction(element, kAXRaiseAction as CFString)
                guard raiseResult == .success else {
                    throw GhosttyWindowActivationError.activationFailed
                }
                return
            }
        }

        throw GhosttyWindowActivationError.noMatchingWindow
    }

    private func stringAttribute(_ attribute: CFString, from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return nil
        }

        return value as? String
    }

    private func pointAttribute(_ attribute: CFString, from element: AXUIElement) -> CGPoint? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let rawValue = value,
              CFGetTypeID(rawValue) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = rawValue as! AXValue
        var point = CGPoint.zero
        guard AXValueGetValue(axValue, .cgPoint, &point) else {
            return nil
        }

        return point
    }

    private func sizeAttribute(_ attribute: CFString, from element: AXUIElement) -> CGSize? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let rawValue = value,
              CFGetTypeID(rawValue) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = rawValue as! AXValue
        var size = CGSize.zero
        guard AXValueGetValue(axValue, .cgSize, &size) else {
            return nil
        }

        return size
    }

    private func frameDistance(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        abs(lhs.origin.x - rhs.origin.x) + abs(lhs.origin.y - rhs.origin.y) + abs(lhs.width - rhs.width) + abs(lhs.height - rhs.height)
    }
}
