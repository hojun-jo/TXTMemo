import AppKit
import Sparkle

@MainActor
final class AppUpdater {
    private let standardUpdaterController: SPUStandardUpdaterController?

    init(bundle: Bundle = .main) {
        if AppUpdaterConfiguration.load(from: bundle) != nil {
            standardUpdaterController = SPUStandardUpdaterController(
                startingUpdater: true,
                updaterDelegate: nil,
                userDriverDelegate: nil
            )
        } else {
            standardUpdaterController = nil
        }
    }

    func configure(checkForUpdatesMenuItem: NSMenuItem) {
        guard let standardUpdaterController else {
            checkForUpdatesMenuItem.target = nil
            checkForUpdatesMenuItem.action = nil
            checkForUpdatesMenuItem.isEnabled = false
            return
        }

        checkForUpdatesMenuItem.target = standardUpdaterController
        checkForUpdatesMenuItem.action = #selector(SPUStandardUpdaterController.checkForUpdates(_:))
    }
}
