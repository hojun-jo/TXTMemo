import Testing
@testable import EditorCore

struct WindowTitleFormatterTests {
    @Test func leavesSavedTitleUnchanged() {
        #expect(WindowTitleFormatter.format(displayName: "meeting-notes.txt", hasUnsavedChanges: false) == "meeting-notes.txt")
    }

    @Test func appendsAsteriskForUnsavedChanges() {
        #expect(WindowTitleFormatter.format(displayName: "Untitled", hasUnsavedChanges: true) == "Untitled *")
    }
}
