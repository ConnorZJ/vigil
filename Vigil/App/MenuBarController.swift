import AppKit

final class MenuBarController {
    private let statusItem: NSStatusItem
    private let appState: AppState
    private var menu: NSMenu?

    init(appState: AppState, statusBar: NSStatusBar = .system) {
        self.appState = appState
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
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
                    action: nil,
                    keyEquivalent: ""
                )
                item.isEnabled = true
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Refresh Mappings", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings", action: nil, keyEquivalent: ""))
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
}
