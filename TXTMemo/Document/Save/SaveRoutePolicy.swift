import AppKit
import Foundation

enum SaveRoutePolicy {
    static func directSaveURL(for operation: NSDocument.SaveOperationType, fileURL: URL?) -> URL? {
        guard operation == .saveOperation else {
            return nil
        }

        return fileURL
    }
}
