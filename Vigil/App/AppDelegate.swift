import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var appState: AppState?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let appState = AppState()
        let menuBarController = MenuBarController(appState: appState)

        self.appState = appState
        self.menuBarController = menuBarController

        appState.bootstrap(seedPreviewData: true)
        Logger.shared.log("Vigil launched")
    }
}
