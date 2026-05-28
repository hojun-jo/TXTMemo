import Foundation

enum DocumentStatePolicy {
    static func hasUnsavedChanges(currentText: String, lastSavedText: String) -> Bool {
        currentText != lastSavedText
    }
}
