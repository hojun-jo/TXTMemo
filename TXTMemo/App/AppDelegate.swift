import AppKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let documentController = NotepadDocumentController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppMenuBuilder.buildMainMenu()
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async { [documentController] in
            documentController.openInitialUntitledDocumentIfNeeded()
        }
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
}
