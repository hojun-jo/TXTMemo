import Foundation
import Testing
@testable import EditorCore

@MainActor
struct EditorSessionControllerTests {
    @Test func clampsIncreaseAndDecreaseWithinRange() {
        let settingsStore = SettingsStore(defaults: UserDefaults(suiteName: #function)!)
        settingsStore.defaultFontSize = 14
        let controller = EditorSessionController(settingsStore: settingsStore)

        controller.setFontSize(FontSizePolicy.maximum)
        controller.increaseFontSize()
        #expect(controller.fontSize == FontSizePolicy.maximum)

        controller.setFontSize(FontSizePolicy.minimum)
        controller.decreaseFontSize()
        #expect(controller.fontSize == FontSizePolicy.minimum)
    }

    @Test func resetsToStoredDefault() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.defaultFontSize = 22

        let controller = EditorSessionController(settingsStore: settingsStore)
        controller.setFontSize(30)
        controller.resetFontSizeToDefault()

        #expect(controller.fontSize == 22)
    }

    @Test func invalidInputRestoresPreviousValue() {
        let settingsStore = SettingsStore(defaults: UserDefaults(suiteName: #function)!)
        let controller = EditorSessionController(settingsStore: settingsStore)

        controller.setFontSize(19)
        controller.commitFontSizeInput("abc")

        #expect(controller.fontSize == 19)
    }

    @Test func wrapStartsEnabledAndTogglesPerSession() {
        let settingsStore = SettingsStore(defaults: UserDefaults(suiteName: #function)!)
        let controller = EditorSessionController(settingsStore: settingsStore)

        #expect(controller.wrapEnabled)

        controller.toggleWrapEnabled()
        #expect(controller.wrapEnabled == false)

        controller.setWrapEnabled(true)
        #expect(controller.wrapEnabled)
    }

    @Test func wrapDoesNotAffectFontSizeState() {
        let settingsStore = SettingsStore(defaults: UserDefaults(suiteName: #function)!)
        let controller = EditorSessionController(settingsStore: settingsStore)

        controller.setFontSize(18)
        controller.toggleWrapEnabled()

        #expect(controller.fontSize == 18)
        #expect(controller.wrapEnabled == false)
    }
}
