enum SaveResult {
    case saved
    case cancelled
    case failed

    var shouldClose: Bool {
        self == .saved
    }
}
