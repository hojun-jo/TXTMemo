import AppKit

final class DocumentWindowController: NSWindowController, NSWindowDelegate {
    private lazy var closeCoordinator = CloseWorkflowCoordinator(document: documentRef, windowController: self)
    private let documentRef: NotepadDocument
    private weak var documentViewController: DocumentWindowViewController?
    private var bypassesCloseConfirmation = false

    init(document: NotepadDocument) {
        let viewController = DocumentWindowViewController(document: document)
        let window = NSWindow(contentViewController: viewController)

        self.documentRef = document
        self.documentViewController = viewController

        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 800, height: 600))
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.isReleasedWhenClosed = false

        super.init(window: window)

        shouldCloseDocument = true
        self.document = document
        window.delegate = self
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

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard !bypassesCloseConfirmation else { return true }

        requestClose(for: .windowClose) { [weak self] shouldClose in
            if shouldClose {
                self?.forceCloseWindow()
            }
        }

        return false
    }

    func requestClose(for context: CloseRequestContext, completion: @escaping (Bool) -> Void) {
        closeCoordinator.requestClose(context: context, completion: completion)
    }

    func forceCloseWindow() {
        guard let window else { return }

        bypassesCloseConfirmation = true
        window.performClose(nil)
        bypassesCloseConfirmation = false
    }

    func commitPendingEditorText() {
        documentViewController?.commitPendingEditorText()
    }
}
