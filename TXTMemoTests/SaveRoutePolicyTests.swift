import AppKit
import Foundation
import Testing
@testable import EditorCore

struct SaveRoutePolicyTests {
    @Test func returnsExistingURLForSaveOperation() {
        let fileURL = URL(fileURLWithPath: "/tmp/note.txt")

        #expect(SaveRoutePolicy.directSaveURL(for: .saveOperation, fileURL: fileURL) == fileURL)
    }

    @Test func returnsNilForSaveOperationWithoutExistingURL() {
        #expect(SaveRoutePolicy.directSaveURL(for: .saveOperation, fileURL: nil) == nil)
    }

    @Test func returnsNilForSaveAsOperationEvenWithExistingURL() {
        let fileURL = URL(fileURLWithPath: "/tmp/note.txt")

        #expect(SaveRoutePolicy.directSaveURL(for: .saveAsOperation, fileURL: fileURL) == nil)
    }
}
