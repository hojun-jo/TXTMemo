import AppKit

final class NotepadDocumentController {
    func openInitialUntitledDocumentIfNeeded() {
        let sharedController = NSDocumentController.shared

        guard sharedController.documents.isEmpty else { return }

        do {
            try sharedController.openUntitledDocumentAndDisplay(true)
        } catch {
            NSApp.presentError(error)
        }
    }
}
