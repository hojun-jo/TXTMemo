import Foundation
import Testing
@testable import EditorCore

struct SettingsStoreTests {
    @MainActor @Test func fallsBackToDefaultForMissingValue() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = SettingsStore(defaults: defaults)

        #expect(store.defaultFontSize == FontSizePolicy.defaultSize)
    }

    @MainActor @Test func clampsStoredValues() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let store = SettingsStore(defaults: defaults)

        store.defaultFontSize = 100
        #expect(store.defaultFontSize == FontSizePolicy.maximum)

        store.defaultFontSize = 1
        #expect(store.defaultFontSize == FontSizePolicy.minimum)
    }
}
