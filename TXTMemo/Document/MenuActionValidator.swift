import Foundation

enum MenuActionValidator {
    static func canIncreaseFontSize(currentFontSize: Int) -> Bool {
        currentFontSize < FontSizePolicy.maximum
    }

    static func canDecreaseFontSize(currentFontSize: Int) -> Bool {
        currentFontSize > FontSizePolicy.minimum
    }
}
