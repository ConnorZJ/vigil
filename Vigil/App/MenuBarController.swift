import AppKit
import SwiftUI

final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let appState: AppState
    private let actions: SessionMenuActions
    private let pixelArtIconProvider = PixelArtMenuIconProvider()
    private let topIconProvider = MenuBarTopIconProvider()
    private let popoverController: StatusItemPopoverController

    init(appState: AppState, statusBar: NSStatusBar = .system) {
        self.appState = appState
        self.actions = appState.menuActions
        self.popoverController = StatusItemPopoverController {
            AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vigil")
                        .font(.headline)

                    Text("Popover migration in progress")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Tracked: \(appState.sessionSnapshots.count)")
                        .font(.caption)
                }
                .padding(12)
                .frame(width: 280)
            )
        }
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.image = makeImage(for: .idle)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover(_:))
        statusItem.button?.sendAction(on: [.leftMouseUp])

        appState.onChange = { [weak self] in
            self?.refreshStatusButton()
        }

        refreshStatusButton()
    }

    private func refreshStatusButton() {
        let presentation = appState.presentation
        statusItem.button?.image = makeImage(for: presentation.iconState)
    }

    private func makeImage(for state: MenuBarIconState) -> NSImage? {
        topIconProvider.image(for: state)
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        popoverController.toggle(relativeTo: sender)
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
