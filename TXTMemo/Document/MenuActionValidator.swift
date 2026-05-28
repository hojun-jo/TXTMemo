import Foundation

enum MenuActionValidator {
    static func canSaveDocument(hasFileURL: Bool, isDocumentEdited: Bool) -> Bool {
        isDocumentEdited || !hasFileURL
    }

    static func canIncreaseFontSize(currentFontSize: Int) -> Bool {
        currentFontSize < FontSizePolicy.maximum
    }

    static func canDecreaseFontSize(currentFontSize: Int) -> Bool {
        currentFontSize > FontSizePolicy.minimum
    }
}
