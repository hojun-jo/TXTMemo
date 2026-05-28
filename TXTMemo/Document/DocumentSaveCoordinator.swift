import AppKit
import UniformTypeIdentifiers

@MainActor
final class DocumentSaveCoordinator {
    private unowned let document: NotepadDocument

    init(document: NotepadDocument) {
        self.document = document
    }

    func saveForClosing(from window: NSWindow, forceSaveAs: Bool, completion: @escaping (Bool) -> Void) {
        let operation: NSDocument.SaveOperationType = forceSaveAs ? .saveAsOperation : .saveOperation
        let typeName = document.fileType ?? document.writableTypes(for: operation).first ?? UTType.plainText.identifier

        if operation == .saveOperation, let fileURL = document.fileURL {
            saveDocument(to: fileURL, typeName: typeName, operation: operation, completion: completion)
            return
        }

        let savePanel = NSSavePanel()
        _ = document.prepareSavePanel(savePanel)
        savePanel.nameFieldStringValue = suggestedSaveFilename()

        savePanel.beginSheetModal(for: window) { response in
            guard response == .OK, let saveURL = savePanel.url else {
                completion(false)
                return
            }

            self.saveDocument(
                to: self.normalizedTextFileURL(from: saveURL),
                typeName: typeName,
                operation: operation,
                completion: completion
            )
        }
    }

    private func saveDocument(to url: URL, typeName: String, operation: NSDocument.SaveOperationType, completion: @escaping (Bool) -> Void) {
        document.save(to: url, ofType: typeName, for: operation) { error in
            if let error {
                NSApp.presentError(error)
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    private func suggestedSaveFilename() -> String {
        if let fileURL = document.fileURL {
            return normalizedTextFileURL(from: fileURL).lastPathComponent
        }

        return normalizedTextFileURL(from: URL(fileURLWithPath: document.displayName)).lastPathComponent
    }

    private func normalizedTextFileURL(from url: URL) -> URL {
        if url.pathExtension.lowercased() == "txt" {
            return url
        }

        return url.deletingPathExtension().appendingPathExtension("txt")
    }
}
