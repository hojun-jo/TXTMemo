import Testing
@testable import EditorCore

struct MenuActionValidatorTests {
    @Test func enablesSaveForUnsavedDocumentEvenWithoutEdits() {
        #expect(MenuActionValidator.canSaveDocument(hasFileURL: false, isDocumentEdited: false))
    }

    @Test func disablesSaveForSavedDocumentWithoutEdits() {
        #expect(!MenuActionValidator.canSaveDocument(hasFileURL: true, isDocumentEdited: false))
    }

    @Test func enablesSaveForEditedDocument() {
        #expect(MenuActionValidator.canSaveDocument(hasFileURL: true, isDocumentEdited: true))
    }

    @Test func enablesIncreaseBelowMaximum() {
        #expect(MenuActionValidator.canIncreaseFontSize(currentFontSize: FontSizePolicy.maximum - 1))
        #expect(!MenuActionValidator.canIncreaseFontSize(currentFontSize: FontSizePolicy.maximum))
    }

    @Test func enablesDecreaseAboveMinimum() {
        #expect(MenuActionValidator.canDecreaseFontSize(currentFontSize: FontSizePolicy.minimum + 1))
        #expect(!MenuActionValidator.canDecreaseFontSize(currentFontSize: FontSizePolicy.minimum))
    }
}
