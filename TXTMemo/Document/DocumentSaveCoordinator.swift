import AppKit
import UniformTypeIdentifiers

@MainActor
final class DocumentSaveCoordinator {
    private unowned let document: NotepadDocument
    private let savePanelService = SavePanelService()

    init(document: NotepadDocument) {
        self.document = document
    }

    func saveForClosing(from window: NSWindow, forceSaveAs: Bool) async -> SaveResult {
        let operation: NSDocument.SaveOperationType = forceSaveAs ? .saveAsOperation : .saveOperation
        let typeName = document.fileType ?? document.writableTypes(for: operation).first ?? UTType.plainText.identifier

        if let fileURL = SaveRoutePolicy.directSaveURL(for: operation, fileURL: document.fileURL) {
            return await saveDocument(to: fileURL, typeName: typeName, operation: operation)
        }

        let saveURL = await savePanelService.beginSaveSheet(for: window, configure: { savePanel in
            _ = document.prepareSavePanel(savePanel)
            savePanel.nameFieldStringValue = SavePanelFilenamePolicy.suggestedFilename(
                documentDisplayName: document.displayName,
                fileURL: document.fileURL
            )
        })

        guard let saveURL else {
            return .cancelled
        }

        return await saveDocument(
            to: SavePanelFilenamePolicy.normalizedTextFileURL(from: saveURL),
            typeName: typeName,
            operation: operation
        )
    }

    private func saveDocument(
        to url: URL,
        typeName: String,
        operation: NSDocument.SaveOperationType
    ) async -> SaveResult {
        await withCheckedContinuation { continuation in
            document.save(to: url, ofType: typeName, for: operation) { error in
                if let error {
                    AlertPresenter.present(error)
                    continuation.resume(returning: .failed)
                } else {
                    continuation.resume(returning: .saved)
                }
            }
        }
    }
}
