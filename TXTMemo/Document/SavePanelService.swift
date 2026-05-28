import AppKit

@MainActor
final class SavePanelService {
    func beginSaveSheet(
        for window: NSWindow,
        configure: (NSSavePanel) -> Void,
        completion: @escaping (URL?) -> Void
    ) {
        let savePanel = NSSavePanel()
        configure(savePanel)
        savePanel.beginSheetModal(for: window) { response in
            guard response == .OK else {
                completion(nil)
                return
            }

            completion(savePanel.url)
        }
    }

    func normalizedTextFileURL(from url: URL) -> URL {
        if url.pathExtension.lowercased() == "txt" {
            return url
        }

        return url.deletingPathExtension().appendingPathExtension("txt")
    }

    func suggestedFilename(documentDisplayName: String, fileURL: URL?) -> String {
        if let fileURL {
            return normalizedTextFileURL(from: fileURL).lastPathComponent
        }

        return normalizedTextFileURL(from: URL(fileURLWithPath: documentDisplayName)).lastPathComponent
    }
}
