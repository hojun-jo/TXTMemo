import Testing
@testable import EditorCore

struct UntitledNameAllocatorTests {
    @Test func usesUntitledAsDefaultDraftName() {
        #expect(UntitledNameAllocator.defaultDraftName() == "Untitled")
    }
}
