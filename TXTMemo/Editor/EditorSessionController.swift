import Foundation

@MainActor
final class EditorSessionController {
    private let settingsStore: SettingsStore
    private var fontSizeObservers: [UUID: (Int) -> Void] = [:]
    private(set) var fontSize: Int {
        didSet {
            notifyFontSizeObservers()
        }
    }

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        fontSize = settingsStore.defaultFontSize
    }

    convenience init() {
        self.init(settingsStore: .shared)
    }

    @discardableResult
    func addFontSizeObserver(_ observer: @escaping (Int) -> Void) -> UUID {
        let id = UUID()
        fontSizeObservers[id] = observer
        observer(fontSize)
        return id
    }

    func removeFontSizeObserver(_ id: UUID) {
        fontSizeObservers.removeValue(forKey: id)
    }

    func increaseFontSize() {
        setFontSize(fontSize + FontSizePolicy.step)
    }

    func decreaseFontSize() {
        setFontSize(fontSize - FontSizePolicy.step)
    }

    func resetFontSizeToDefault() {
        setFontSize(settingsStore.defaultFontSize)
    }

    func commitFontSizeInput(_ value: String?) {
        guard let value, !value.isEmpty, let parsed = Int(value) else {
            notifyFontSizeObservers()
            return
        }

        setFontSize(parsed)
    }

    func setFontSize(_ size: Int) {
        let clampedSize = FontSizePolicy.clamp(size)
        guard clampedSize != fontSize else {
            notifyFontSizeObservers()
            return
        }

        fontSize = clampedSize
    }

    private func notifyFontSizeObservers() {
        for observer in fontSizeObservers.values {
            observer(fontSize)
        }
    }
}
