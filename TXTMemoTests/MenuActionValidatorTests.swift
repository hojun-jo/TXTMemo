import Testing
@testable import EditorCore

struct MenuActionValidatorTests {
    @Test func enablesIncreaseBelowMaximum() {
        #expect(MenuActionValidator.canIncreaseFontSize(currentFontSize: FontSizePolicy.maximum - 1))
        #expect(!MenuActionValidator.canIncreaseFontSize(currentFontSize: FontSizePolicy.maximum))
    }

    @Test func enablesDecreaseAboveMinimum() {
        #expect(MenuActionValidator.canDecreaseFontSize(currentFontSize: FontSizePolicy.minimum + 1))
        #expect(!MenuActionValidator.canDecreaseFontSize(currentFontSize: FontSizePolicy.minimum))
    }
}
