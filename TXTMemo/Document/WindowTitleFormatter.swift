import Foundation

enum WindowTitleFormatter {
    static func format(displayName: String, hasUnsavedChanges: Bool) -> String {
        hasUnsavedChanges ? "\(displayName) *" : displayName
    }
}
