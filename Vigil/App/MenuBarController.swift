import AppKit

final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let appState: AppState
    private var menu: NSMenu?
    private let actions: SessionMenuActions

    init(appState: AppState, statusBar: NSStatusBar = .system) {
        self.appState = appState
        self.actions = appState.menuActions
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.image = makeImage(for: .idle)

        appState.onChange = { [weak self] in
            self?.rebuildMenu()
        }

        rebuildMenu()
    }

    private func rebuildMenu() {
        let presentation = appState.presentation
        statusItem.button?.image = makeImage(for: presentation.iconState)

        let menu = NSMenu()

        for (sectionIndex, section) in presentation.sections.enumerated() {
            if sectionIndex > 0 {
                menu.addItem(.separator())
            }

            let header = NSMenuItem()
            header.title = section.title
            header.isEnabled = false
            menu.addItem(header)

            if let summaryText = section.summaryText {
                let summaryItem = NSMenuItem(title: summaryText, action: nil, keyEquivalent: "")
                summaryItem.isEnabled = false
                menu.addItem(summaryItem)
            }

            for row in section.rows {
                let item = NSMenuItem(
                    title: "[\(row.statusText)] \(row.title) - \(row.projectName) - \(row.relativeUpdatedText)",
                    action: #selector(openSessionFromMenu(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = row.sessionId
                menu.addItem(item)

                let bindItem = NSMenuItem(
                    title: "Bind Frontmost to \(row.title)",
                    action: #selector(bindFrontmostWindowFromMenu(_:)),
                    keyEquivalent: ""
                )
                bindItem.target = self
                bindItem.representedObject = row.sessionId
                menu.addItem(bindItem)
            }
        }

        menu.addItem(.separator())
        let refreshItem = NSMenuItem(title: "Refresh Mappings", action: #selector(refreshMappings(_:)), keyEquivalent: "")
        refreshItem.target = self
        menu.addItem(refreshItem)

        let settingsItem = NSMenuItem(title: "Request Accessibility", action: #selector(openSettings(_:)), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())
        let diagnosticsHeader = NSMenuItem(title: "Diagnostics", action: nil, keyEquivalent: "")
        diagnosticsHeader.isEnabled = false
        menu.addItem(diagnosticsHeader)

        let diagnostics = appState.diagnosticsSnapshot
        for line in [
            diagnostics.transportStatus,
            diagnostics.bridgeStatus,
            "Accessibility: \(diagnostics.accessibilityStatus)",
            "Last Event: \(diagnostics.lastEventText)",
        ] {
            let item = NSMenuItem(title: line, action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }

        if let lastJumpError = diagnostics.lastJumpError {
            let errorItem = NSMenuItem(title: "Last Jump Error: \(lastJumpError)", action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            menu.addItem(errorItem)
        }

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        self.menu = menu
        statusItem.menu = menu
    }

    private func makeImage(for state: MenuBarIconState) -> NSImage? {
        let symbolName: String

        switch state {
        case .idle:
            symbolName = "circle"
        case .running:
            symbolName = "bolt.horizontal.circle"
        case .waitingInput:
            symbolName = "ellipsis.circle"
        case .permission:
            symbolName = "exclamationmark.shield"
        case .complete:
            symbolName = "checkmark.circle"
        case .error:
            symbolName = "xmark.octagon"
        }

        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Vigil status")
        image?.isTemplate = true
        return image
    }

    @objc private func openSessionFromMenu(_ sender: NSMenuItem) {
        guard let sessionId = sender.representedObject as? String else {
            return
        }

        actions.openSession(sessionId)
    }

    @objc private func bindFrontmostWindowFromMenu(_ sender: NSMenuItem) {
        guard let sessionId = sender.representedObject as? String else {
            return
        }

        actions.bindFrontmostWindow(sessionId)
    }

    @objc private func refreshMappings(_ sender: NSMenuItem) {
        actions.refreshMappings()
    }

    @objc private func openSettings(_ sender: NSMenuItem) {
        actions.openSettings()
    }
}
