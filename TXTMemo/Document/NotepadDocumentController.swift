import AppKit

final class NotepadDocumentController {
    func openInitialUntitledDocumentIfNeeded() {
        let sharedController = NSDocumentController.shared

        if revealExistingDocumentWindowsIfNeeded(in: sharedController) {
            return
        }

        do {
            let document = try sharedController.openUntitledDocumentAndDisplay(true)
            revealWindows(for: document)
        } catch {
            NSApp.presentError(error)
        }
    }

    private func revealExistingDocumentWindowsIfNeeded(in controller: NSDocumentController) -> Bool {
        guard !controller.documents.isEmpty else { return false }

        var revealedAnyWindow = false

        for document in controller.documents {
            if document.windowControllers.isEmpty {
                document.makeWindowControllers()
            }

            revealedAnyWindow = revealWindows(for: document) || revealedAnyWindow
        }

        return revealedAnyWindow
    }

    @discardableResult
    private func revealWindows(for document: NSDocument) -> Bool {
        var revealedAnyWindow = false

        for windowController in document.windowControllers {
            windowController.showWindow(nil)

            guard let window = windowController.window else { continue }

            if window.isMiniaturized {
                window.deminiaturize(nil)
            }

            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
            revealedAnyWindow = true
        }

        if revealedAnyWindow {
            NSApp.activate(ignoringOtherApps: true)
        }

        return revealedAnyWindow
    }
}
