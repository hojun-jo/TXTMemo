import AppKit

@MainActor
struct NotepadDocumentDependencies {
    let settingsStore: SettingsStore
    let savePanelService: any SavePanelServing

    static let live = NotepadDocumentDependencies(
        settingsStore: SettingsStore(),
        savePanelService: SavePanelService()
    )
}
