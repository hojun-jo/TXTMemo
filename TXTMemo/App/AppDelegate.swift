import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appUpdater = AppUpdater()
    private let settingsStore = SettingsStore()
    private let savePanelService = SavePanelService()
    private let documentController = NotepadDocumentController()
    private let terminationCoordinator = AppTerminationCoordinator()
    private lazy var preferencesWindowController = PreferencesWindowController(settingsStore: settingsStore)
    private var hasPendingExternalDocumentOpen = false

    override init() {
        super.init()
        NotepadDocument.dependencies = NotepadDocumentDependencies(
            settingsStore: settingsStore,
            savePanelService: savePanelService
        )
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        installMainMenu()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMainMenu()
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard !self.hasPendingExternalDocumentOpen else { return }
            guard NSDocumentController.shared.documents.isEmpty else { return }

            self.documentController.openInitialUntitledDocument()
        }
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        hasPendingExternalDocumentOpen = true

        guard !filenames.isEmpty else {
            sender.reply(toOpenOrPrint: .failure)
            return
        }

        let urls = filenames.map { URL(fileURLWithPath: $0) }
        openDocuments(at: urls, replyingTo: sender)
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
            if !documentController.revealExistingDocumentsIfNeeded() {
                documentController.openInitialUntitledDocument()
            }
        }

        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        terminationCoordinator.beginTermination(for: sender)
    }

    @objc func showPreferences(_ sender: Any?) {
        preferencesWindowController.showWindowAndFocus()
    }

    private func installMainMenu() {
        let menuReferences = AppMenuBuilder.buildMainMenu()
        appUpdater.configure(checkForUpdatesMenuItem: menuReferences.checkForUpdatesItem)
    }

    private func openDocuments(at urls: [URL], replyingTo application: NSApplication) {
        var remaining = urls.count
        var didFail = false

        for url in urls {
            NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
                if let error {
                    didFail = true
                    AlertPresenter.present(error)
                }

                remaining -= 1

                if remaining == 0 {
                    application.reply(toOpenOrPrint: didFail ? .failure : .success)
                }
            }
        }
    }
}
