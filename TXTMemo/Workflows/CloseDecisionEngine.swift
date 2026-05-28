import Foundation

enum CloseDecision {
    case closeImmediately
    case presentConfirmation
}

enum CloseDecisionEngine {
    static func decide(text: String, isDocumentEdited: Bool) -> CloseDecision {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .closeImmediately
        }

        return isDocumentEdited ? .presentConfirmation : .closeImmediately
    }
}
