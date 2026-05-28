import AppKit

final class NotepadDocumentController {
    func revealExistingDocumentsIfNeeded() -> Bool {
        let sharedController = NSDocumentController.shared

        guard !sharedController.documents.isEmpty else {
            return false
        }

        var revealedAnyWindow = false

        for document in sharedController.documents {
            if document.windowControllers.isEmpty {
                document.makeWindowControllers()
            }

            revealedAnyWindow = revealWindows(for: document) || revealedAnyWindow
        }

        return revealedAnyWindow
    }

    func openInitialUntitledDocument() {
        let sharedController = NSDocumentController.shared

        do {
            let document = try sharedController.openUntitledDocumentAndDisplay(true)
            revealWindows(for: document)
        } catch {
            AlertPresenter.present(error)
        }
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
