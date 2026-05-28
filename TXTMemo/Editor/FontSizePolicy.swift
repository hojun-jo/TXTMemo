enum FontSizePolicy {
    static let minimum = 8
    static let maximum = 72
    static let defaultSize = 14
    static let step = 1

    static func clamp(_ size: Int) -> Int {
        min(max(size, minimum), maximum)
    }
}
