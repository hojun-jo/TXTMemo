import XCTest
@testable import CloseWorkflowCore

final class CloseDecisionEngineTests: XCTestCase {
    func testCloseImmediatelyForWhitespaceOnlyEditedText() {
        let decision = CloseDecisionEngine.decide(text: " \n\t ", isDocumentEdited: true)

        XCTAssertEqual(decision, .closeImmediately)
    }

    func testCloseImmediatelyForSavedDocumentWithContent() {
        let decision = CloseDecisionEngine.decide(text: "memo", isDocumentEdited: false)

        XCTAssertEqual(decision, .closeImmediately)
    }

    func testPresentConfirmationForEditedDocumentWithContent() {
        let decision = CloseDecisionEngine.decide(text: "memo", isDocumentEdited: true)

        XCTAssertEqual(decision, .presentConfirmation)
    }
}
