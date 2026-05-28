import AppKit

@MainActor
final class SavePanelService {
    func beginSaveSheet(
        for window: NSWindow,
        configure: (NSSavePanel) -> Void,
        completion: @escaping (URL?) -> Void
    ) {
        let savePanel = NSSavePanel()
        configure(savePanel)
        savePanel.beginSheetModal(for: window) { response in
            guard response == .OK else {
                completion(nil)
                return
            }

            completion(savePanel.url)
        }
    }
}
