import AppKit

@MainActor
final class SavePanelService {
    func beginSaveSheet(
        for window: NSWindow,
        configure: (NSSavePanel) -> Void
    ) async -> URL? {
        let savePanel = NSSavePanel()
        configure(savePanel)

        return await withCheckedContinuation { continuation in
            savePanel.beginSheetModal(for: window) { response in
                guard response == .OK else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: savePanel.url)
            }
        }
    }
}
