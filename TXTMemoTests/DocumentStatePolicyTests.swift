import Testing
@testable import EditorCore

struct DocumentStatePolicyTests {
    @Test func detectsUnsavedChangesWhenCurrentTextDiffers() {
        #expect(DocumentStatePolicy.hasUnsavedChanges(currentText: "edited", lastSavedText: "saved"))
    }

    @Test func clearsUnsavedChangesWhenCurrentTextMatchesSavedText() {
        #expect(!DocumentStatePolicy.hasUnsavedChanges(currentText: "same", lastSavedText: "same"))
    }
}
