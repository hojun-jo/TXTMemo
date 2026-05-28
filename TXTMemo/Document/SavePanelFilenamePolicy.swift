import Foundation

enum SavePanelFilenamePolicy {
    static func normalizedTextFileURL(from url: URL) -> URL {
        if url.pathExtension.lowercased() == "txt" {
            return url
        }

        return url.deletingPathExtension().appendingPathExtension("txt")
    }

    static func suggestedFilename(documentDisplayName: String, fileURL: URL?) -> String {
        if let fileURL {
            return normalizedTextFileURL(from: fileURL).lastPathComponent
        }

        return normalizedTextFileURL(from: URL(fileURLWithPath: documentDisplayName)).lastPathComponent
    }
}
