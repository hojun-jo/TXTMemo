import AppKit
import UniformTypeIdentifiers

final class NotepadDocument: NSDocument {
    private nonisolated(unsafe) var textContent = ""
    private nonisolated(unsafe) var lastSavedText = ""
    private var untitledDisplayIndex: Int?
    private lazy var saveCoordinator = DocumentSaveCoordinator(document: self)

    override init() {
        super.init()
        hasUndoManager = true
    }

    nonisolated override class var autosavesInPlace: Bool {
        false
    }

    override func defaultDraftName() -> String {
        if untitledDisplayIndex == nil {
            untitledDisplayIndex = UntitledNameAllocator.allocateDisplayIndex(
                usedDisplayIndices: NSDocumentController.shared.documents.compactMap { document in
                    guard let document = document as? NotepadDocument, document !== self, document.fileURL == nil else {
                        return nil
                    }

                    return document.untitledDisplayIndex
                }
            )
        }

        return UntitledNameAllocator.defaultDraftName(for: untitledDisplayIndex ?? 1)
    }

    override func makeWindowControllers() {
        let windowController = DocumentWindowController(document: self)
        addWindowController(windowController)
    }

    override func prepareSavePanel(_ savePanel: NSSavePanel) -> Bool {
        savePanel.allowedContentTypes = [.plainText]
        savePanel.allowsOtherFileTypes = false
        savePanel.isExtensionHidden = false
        savePanel.canSelectHiddenExtension = false
        return super.prepareSavePanel(savePanel)
    }

    override func save(_ sender: Any?) {
        prepareToSave()
        super.save(sender)
    }

    override func saveAs(_ sender: Any?) {
        prepareToSave()
        super.saveAs(sender)
    }

    nonisolated override func data(ofType typeName: String) throws -> Data {
        try TextFileCodec.writeUTF8Text(textContent)
    }

    nonisolated override func read(from data: Data, ofType typeName: String) throws {
        let decoded = try TextFileCodec.readText(from: data)

        textContent = decoded
        lastSavedText = decoded
    }

    override func save(to url: URL, ofType typeName: String, for saveOperation: SaveOperationType, completionHandler: @escaping (Error?) -> Void) {
        super.save(to: url, ofType: typeName, for: saveOperation) { [weak self] error in
            if error == nil, let self {
                self.lastSavedText = self.textContent
                self.refreshWindowTitles()
            }

            completionHandler(error)
        }
    }

    override func canClose(withDelegate delegate: Any, shouldClose shouldCloseSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
        guard let shouldCloseSelector else { return }

        typealias CloseHandler = @convention(c) (AnyObject, Selector, NSDocument, Bool, UnsafeMutableRawPointer?) -> Void
        let target = delegate as AnyObject
        let implementation = target.method(for: shouldCloseSelector)
        let function = unsafeBitCast(implementation, to: CloseHandler.self)
        function(target, shouldCloseSelector, self, true, contextInfo)
    }

    func currentText() -> String {
        textContent
    }

    func replaceText(with newText: String) {
        guard newText != textContent else { return }

        textContent = newText
        synchronizeEditedState()
    }

    func recomputeEditedState(for currentText: String) {
        textContent = currentText
        synchronizeEditedState()
    }

    func isSyncedToSavedText(_ text: String) -> Bool {
        text == lastSavedText
    }

    private func synchronizeEditedState() {
        let isEdited = DocumentStatePolicy.hasUnsavedChanges(currentText: textContent, lastSavedText: lastSavedText)

        if !isEdited {
            updateChangeCount(.changeCleared)
        } else {
            updateChangeCount(.changeDone)
        }

        refreshWindowTitles()
    }

    func saveForClosing(from window: NSWindow, forceSaveAs: Bool, completion: @escaping (Bool) -> Void) {
        saveCoordinator.saveForClosing(from: window, forceSaveAs: forceSaveAs, completion: completion)
    }

    private func refreshWindowTitles() {
        for case let windowController as DocumentWindowController in windowControllers {
            windowController.synchronizeWindowTitleWithDocumentName()
        }
    }

    private func prepareToSave() {
        for case let windowController as DocumentWindowController in windowControllers {
            if windowController.window?.isKeyWindow == true {
                windowController.prepareToSave()
                return
            }
        }

        (windowControllers.first as? DocumentWindowController)?.prepareToSave()
    }

}
