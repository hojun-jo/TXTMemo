import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settingsStore = SettingsStore()
    private let savePanelService = SavePanelService()
    private let documentController = NotepadDocumentController()
    private let terminationCoordinator = AppTerminationCoordinator()
    private lazy var preferencesWindowController = PreferencesWindowController(settingsStore: settingsStore)

    override init() {
        super.init()
        NotepadDocument.dependencies = NotepadDocumentDependencies(
            settingsStore: settingsStore,
            savePanelService: savePanelService
        )
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        AppMenuBuilder.buildMainMenu()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppMenuBuilder.buildMainMenu()
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async { [documentController] in
            documentController.openInitialUntitledDocumentIfNeeded()
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        false
    }

    func application(_ app: NSApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return false
    }

    func application(_ app: NSApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return false
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            documentController.openInitialUntitledDocumentIfNeeded()
        }

        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        terminationCoordinator.beginTermination(for: sender)
    }

    @objc func showPreferences(_ sender: Any?) {
        preferencesWindowController.showWindowAndFocus()
    }
}
