import Foundation

enum UntitledNameAllocator {
    private static let baseName = "Untitled"

    static func allocateDisplayIndex(usedDisplayIndices: some Sequence<Int>) -> Int {
        let usedIndices = Set(usedDisplayIndices)
        var candidate = 1

        while usedIndices.contains(candidate) {
            candidate += 1
        }

        return candidate
    }

    static func defaultDraftName(for displayIndex: Int) -> String {
        guard displayIndex > 1 else {
            return baseName
        }

        return "\(baseName) \(displayIndex)"
    }
}
