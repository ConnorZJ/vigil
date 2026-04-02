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
    private var animationTimer: Timer?
    private var currentIconState: MenuBarIconState = .idle
    private var currentAnimationFrame = 0
    private var settleToStaticAfterNextTick = false

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
        configureAnimation(for: presentation.iconState)
        updateStatusImage()
    }

    private func makeImage(for state: MenuBarIconState) -> NSImage? {
        topIconProvider.image(for: state, frame: currentAnimationFrame)
    }

    private func configureAnimation(for state: MenuBarIconState) {
        if currentIconState != state {
            currentIconState = state
            currentAnimationFrame = 0
        }

        animationTimer?.invalidate()
        animationTimer = nil
        settleToStaticAfterNextTick = false

        switch state {
        case .running, .waitingInput, .permission:
            animationTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
                guard let self else { return }
                self.currentAnimationFrame = (self.currentAnimationFrame + 1) % max(1, self.topIconProvider.frameCount(for: state))
                self.updateStatusImage()
            }
        case .complete, .error:
            settleToStaticAfterNextTick = true
            animationTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { [weak self] timer in
                guard let self else { return }
                self.currentAnimationFrame = 1
                self.updateStatusImage()
                if self.settleToStaticAfterNextTick {
                    self.settleToStaticAfterNextTick = false
                    self.currentAnimationFrame = 0
                    self.updateStatusImage()
                    timer.invalidate()
                    self.animationTimer = nil
                }
            }
        case .idle:
            currentAnimationFrame = 0
        }
    }

    private func updateStatusImage() {
        statusItem.button?.image = makeImage(for: currentIconState)
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
