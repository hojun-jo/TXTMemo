import Testing
@testable import EditorCore

struct SaveResultTests {
    @Test func onlySavedResultAllowsClose() {
        #expect(SaveResult.saved.shouldClose)
        #expect(!SaveResult.cancelled.shouldClose)
        #expect(!SaveResult.failed.shouldClose)
    }
}
