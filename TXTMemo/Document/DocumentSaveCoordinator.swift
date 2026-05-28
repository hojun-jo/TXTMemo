import AppKit
import UniformTypeIdentifiers

@MainActor
final class DocumentSaveCoordinator {
    private unowned let document: NotepadDocument
    private let savePanelService = SavePanelService()

    init(document: NotepadDocument) {
        self.document = document
    }

    func saveForClosing(from window: NSWindow, forceSaveAs: Bool, completion: @escaping (Bool) -> Void) {
        let operation: NSDocument.SaveOperationType = forceSaveAs ? .saveAsOperation : .saveOperation
        let typeName = document.fileType ?? document.writableTypes(for: operation).first ?? UTType.plainText.identifier
        let finish: (SaveResult) -> Void = { result in
            completion(result.shouldClose)
        }

        if let fileURL = SaveRoutePolicy.directSaveURL(for: operation, fileURL: document.fileURL) {
            saveDocument(to: fileURL, typeName: typeName, operation: operation, completion: finish)
            return
        }

        savePanelService.beginSaveSheet(for: window, configure: { savePanel in
            _ = document.prepareSavePanel(savePanel)
            savePanel.nameFieldStringValue = SavePanelFilenamePolicy.suggestedFilename(
                documentDisplayName: document.displayName,
                fileURL: document.fileURL
            )
        }) { saveURL in
            guard let saveURL else {
                finish(.cancelled)
                return
            }

            self.saveDocument(
                to: SavePanelFilenamePolicy.normalizedTextFileURL(from: saveURL),
                typeName: typeName,
                operation: operation,
                completion: finish
            )
        }
    }

    private func saveDocument(
        to url: URL,
        typeName: String,
        operation: NSDocument.SaveOperationType,
        completion: @escaping (SaveResult) -> Void
    ) {
        document.save(to: url, ofType: typeName, for: operation) { error in
            if let error {
                AlertPresenter.present(error)
                completion(.failed)
            } else {
                completion(.saved)
            }
        }
    }
}
