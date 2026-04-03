import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

enum GhosttyQueryError: Error {
    case appNotRunning
}

struct GhosttyAXWindowQueryService: GhosttyWindowQuerying {
    private let workspace: NSWorkspace

    init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
    }

    func currentWindows() throws -> [GhosttyWindowDescriptor] {
        guard let app = ghosttyApp() else {
            throw GhosttyQueryError.appNotRunning
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value)
        guard result == .success, let windowElements = value as? [AXUIElement] else {
            return []
        }

        return windowElements.compactMap(descriptor(from:))
    }

    func frontmostWindow() throws -> GhosttyWindowDescriptor? {
        try currentWindows().first(where: \ .isFocused)
    }

    private func ghosttyApp() -> NSRunningApplication? {
        workspace.runningApplications.first { application in
            application.bundleIdentifier == "com.mitchellh.ghostty" || application.localizedName == "Ghostty"
        }
    }

    private func descriptor(from element: AXUIElement) -> GhosttyWindowDescriptor? {
        let title = stringAttribute(kAXTitleAttribute as CFString, from: element) ?? "Ghostty"
        let position = pointAttribute(kAXPositionAttribute as CFString, from: element) ?? .zero
        let size = sizeAttribute(kAXSizeAttribute as CFString, from: element) ?? .zero
        let focused = boolAttribute(kAXFocusedAttribute as CFString, from: element) ?? false
        let document = stringAttribute(kAXDocumentAttribute as CFString, from: element)
        let cwd = document.map { path in
            let url = URL(fileURLWithPath: path)
            return url.hasDirectoryPath ? url.path : url.deletingLastPathComponent().path
        }

        return GhosttyWindowDescriptor(
            title: title,
            frame: CGRect(origin: position, size: size),
            isFocused: focused,
            cwd: cwd,
            tabTitle: title,
            tty: nil
        )
    }

    private func stringAttribute(_ attribute: CFString, from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return nil
        }

        return value as? String
    }

    private func boolAttribute(_ attribute: CFString, from element: AXUIElement) -> Bool? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let number = value as? NSNumber else {
            return nil
        }

        return number.boolValue
    }

    private func pointAttribute(_ attribute: CFString, from element: AXUIElement) -> CGPoint? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let axValue = value,
              CFGetTypeID(axValue) == AXValueGetTypeID() else {
            return nil
        }

        let ax = axValue as! AXValue
        guard AXValueGetType(ax) == .cgPoint else {
            return nil
        }

        var point = CGPoint.zero
        guard AXValueGetValue(ax, .cgPoint, &point) else {
            return nil
        }

        return point
    }

    private func sizeAttribute(_ attribute: CFString, from element: AXUIElement) -> CGSize? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let axValue = value,
              CFGetTypeID(axValue) == AXValueGetTypeID() else {
            return nil
        }

        let ax = axValue as! AXValue
        guard AXValueGetType(ax) == .cgSize else {
            return nil
        }

        var size = CGSize.zero
        guard AXValueGetValue(ax, .cgSize, &size) else {
            return nil
        }

        return size
    }
}
