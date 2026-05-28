import Testing
@testable import EditorCore

struct UntitledNameAllocatorTests {
    @Test func usesUntitledAsDefaultDraftName() {
        #expect(UntitledNameAllocator.defaultDraftName(for: 1) == "Untitled")
    }

    @Test func appendsDisplayIndexAfterFirstUntitledDocument() {
        #expect(UntitledNameAllocator.defaultDraftName(for: 2) == "Untitled 2")
        #expect(UntitledNameAllocator.defaultDraftName(for: 3) == "Untitled 3")
    }

    @Test func allocatesLowestAvailableDisplayIndex() {
        #expect(UntitledNameAllocator.allocateDisplayIndex(usedDisplayIndices: [1, 2, 4]) == 3)
        #expect(UntitledNameAllocator.allocateDisplayIndex(usedDisplayIndices: [2, 3]) == 1)
    }
}
