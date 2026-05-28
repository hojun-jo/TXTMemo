import AppKit

final class DocumentWindowController: NSWindowController {
    init(document: NotepadDocument) {
        let viewController = DocumentWindowViewController(document: document)
        let window = NSWindow(contentViewController: viewController)

        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 800, height: 600))
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.isReleasedWhenClosed = false

        super.init(window: window)

        shouldCloseDocument = true
        self.document = document
        synchronizeWindowTitleWithDocumentName()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func windowTitle(forDocumentDisplayName displayName: String) -> String {
        guard let document else { return displayName }
        return document.isDocumentEdited ? "\(displayName) *" : displayName
    }

    override func synchronizeWindowTitleWithDocumentName() {
        super.synchronizeWindowTitleWithDocumentName()
    }
}
