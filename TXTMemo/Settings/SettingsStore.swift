import Foundation

@MainActor
final class SettingsStore {
    static let shared = SettingsStore()

    private let defaults: UserDefaults
    private let defaultFontSizeKey = "defaultFontSize"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var defaultFontSize: Int {
        get {
            let storedValue = defaults.object(forKey: defaultFontSizeKey) as? Int
            return FontSizePolicy.clamp(storedValue ?? FontSizePolicy.defaultSize)
        }
        set {
            defaults.set(FontSizePolicy.clamp(newValue), forKey: defaultFontSizeKey)
        }
    }
}
