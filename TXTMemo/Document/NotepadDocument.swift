import AppKit
import UniformTypeIdentifiers

final class NotepadDocument: NSDocument {
    private nonisolated(unsafe) var textContent = ""
    private nonisolated(unsafe) var lastSavedText = ""

    override init() {
        super.init()
        hasUndoManager = true
    }

    nonisolated override class var autosavesInPlace: Bool {
        false
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
        guard let data = textContent.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }

        return data
    }

    nonisolated override func read(from data: Data, ofType typeName: String) throws {
        guard let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }

        textContent = string
        lastSavedText = string
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
        let isEdited = textContent != lastSavedText

        if !isEdited {
            updateChangeCount(.changeCleared)
        } else {
            updateChangeCount(.changeDone)
        }

        refreshWindowTitles()
    }

    func saveForClosing(from window: NSWindow, forceSaveAs: Bool, completion: @escaping (Bool) -> Void) {
        let typeName = fileType ?? writableTypes(for: forceSaveAs ? .saveAsOperation : .saveOperation).first ?? UTType.plainText.identifier

        if !forceSaveAs, let fileURL {
            save(to: fileURL, ofType: typeName, for: .saveOperation) { error in
                if let error {
                    NSApp.presentError(error)
                    completion(false)
                } else {
                    completion(true)
                }
            }

            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.allowsOtherFileTypes = false
        savePanel.canSelectHiddenExtension = false
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = suggestedSaveFilename()

        savePanel.beginSheetModal(for: window) { [weak self] response in
            guard let self else {
                completion(false)
                return
            }

            guard response == .OK, let saveURL = savePanel.url else {
                completion(false)
                return
            }

            let normalizedURL = normalizedTextFileURL(from: saveURL)
            let operation: SaveOperationType = forceSaveAs ? .saveAsOperation : .saveOperation

            save(to: normalizedURL, ofType: typeName, for: operation) { error in
                if let error {
                    NSApp.presentError(error)
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
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

    private func suggestedSaveFilename() -> String {
        if let fileURL {
            return normalizedTextFileURL(from: fileURL).lastPathComponent
        }

        return normalizedTextFileURL(from: URL(fileURLWithPath: displayName)).lastPathComponent
    }

    private func normalizedTextFileURL(from url: URL) -> URL {
        if url.pathExtension.lowercased() == "txt" {
            return url
        }

        return url.deletingPathExtension().appendingPathExtension("txt")
    }
}
