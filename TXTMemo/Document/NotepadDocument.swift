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

    func currentText() -> String {
        textContent
    }

    func replaceText(with newText: String) {
        guard newText != textContent else { return }

        textContent = newText
        let isEdited = textContent != lastSavedText

        if !isEdited {
            updateChangeCount(.changeCleared)
        } else {
            updateChangeCount(.changeDone)
        }

        refreshWindowTitles()
    }

    private func refreshWindowTitles() {
        for case let windowController as DocumentWindowController in windowControllers {
            windowController.synchronizeWindowTitleWithDocumentName()
        }
    }
}
