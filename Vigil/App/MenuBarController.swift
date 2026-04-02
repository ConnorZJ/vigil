import AppKit

final class MenuBarController {
    private let statusItem: NSStatusItem

    init(statusBar: NSStatusBar = .system) {
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "Vigil"
    }
}
