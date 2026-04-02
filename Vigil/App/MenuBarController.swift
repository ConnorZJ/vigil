import AppKit
import SwiftUI

final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let appState: AppState
    private let actions: SessionMenuActions
    private let pixelArtIconProvider = PixelArtMenuIconProvider()
    private let topIconProvider = MenuBarTopIconProvider()
    private let popoverController: StatusItemPopoverController
    private let popoverPresentationBuilder = PopoverPresentationBuilder()

    init(appState: AppState, statusBar: NSStatusBar = .system) {
        self.appState = appState
        self.actions = appState.menuActions
        self.popoverController = StatusItemPopoverController { AnyView(EmptyView()) }
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        popoverController.rootViewProvider = { [weak self] in
            guard let self else {
                return AnyView(EmptyView())
            }

            return AnyView(self.makePopoverRootView())
        }
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

    private func makePopoverRootView() -> some View {
        let presentation = popoverPresentationBuilder.build(
            from: appState.sessionSnapshots,
            diagnostics: appState.diagnosticsSnapshot,
            now: Date()
        )

        return PopoverRootView(presentation: presentation, actions: makePopoverActions())
    }

    private func makePopoverActions() -> SessionMenuActions {
        SessionMenuActions(
            openSession: { [weak self] sessionId in
                guard let self else { return }
                let succeeded = self.appState.openSession(sessionId: sessionId)
                if PopoverDismissPolicy.shouldClose(for: .jump, succeeded: succeeded) {
                    self.popoverController.close()
                }
            },
            bindFrontmostWindow: { [weak self] sessionId in
                guard let self else { return }
                let succeeded = self.appState.bindFrontmostWindow(sessionId: sessionId)
                if PopoverDismissPolicy.shouldClose(for: .bind, succeeded: succeeded) {
                    self.popoverController.close()
                }
            },
            refreshMappings: { [weak self] in
                guard let self else { return }
                self.appState.refreshMappings()
                if PopoverDismissPolicy.shouldClose(for: .refresh, succeeded: true) {
                    self.popoverController.close()
                }
            },
            openSettings: { [weak self] in
                guard let self else { return }
                self.appState.requestAccessibilityPermission()
                if PopoverDismissPolicy.shouldClose(for: .accessibility, succeeded: true) {
                    self.popoverController.close()
                }
            }
        )
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
