import Foundation
import Testing
@testable import EditorCore

struct SavePanelFilenamePolicyTests {
    @Test func keepsTxtExtensionWhenAlreadyPresent() {
        let url = URL(fileURLWithPath: "/tmp/notes.txt")

        #expect(SavePanelFilenamePolicy.normalizedTextFileURL(from: url) == url)
    }

    @Test func normalizesMissingExtensionToTxt() {
        let url = URL(fileURLWithPath: "/tmp/notes")

        #expect(SavePanelFilenamePolicy.normalizedTextFileURL(from: url).path == "/tmp/notes.txt")
    }

    @Test func normalizesNonTxtExtensionToTxt() {
        let url = URL(fileURLWithPath: "/tmp/notes.md")

        #expect(SavePanelFilenamePolicy.normalizedTextFileURL(from: url).path == "/tmp/notes.txt")
    }

    @Test func suggestsNormalizedFilenameFromCurrentFileURL() {
        let fileURL = URL(fileURLWithPath: "/tmp/draft.md")

        #expect(
            SavePanelFilenamePolicy.suggestedFilename(documentDisplayName: "Untitled", fileURL: fileURL) == "draft.txt"
        )
    }

    @Test func suggestsNormalizedFilenameFromDisplayNameWhenUnsaved() {
        #expect(
            SavePanelFilenamePolicy.suggestedFilename(documentDisplayName: "Untitled 2", fileURL: nil) == "Untitled 2.txt"
        )
    }
}
