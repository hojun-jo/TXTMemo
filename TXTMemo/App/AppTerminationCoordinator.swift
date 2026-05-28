import AppKit

@MainActor
final class AppTerminationCoordinator {
    private weak var application: NSApplication?
    private var pendingControllers: [DocumentWindowController] = []
    private var isRunning = false

    func beginTermination(for application: NSApplication) -> NSApplication.TerminateReply {
        let controllers = orderedWindowControllers()

        guard !controllers.isEmpty else {
            return .terminateNow
        }

        guard !isRunning else {
            return .terminateLater
        }

        self.application = application
        pendingControllers = controllers
        isRunning = true
        Task { @MainActor [weak self] in
            await self?.processNextController()
        }

        return .terminateLater
    }

    private func processNextController() async {
        guard !pendingControllers.isEmpty else {
            finish(shouldTerminate: true)
            return
        }

        let controller = pendingControllers.removeFirst()

        if await controller.requestClose(for: .appTermination) {
            controller.forceCloseWindow()
            await processNextController()
        } else {
            finish(shouldTerminate: false)
        }
    }

    private func finish(shouldTerminate: Bool) {
        isRunning = false
        pendingControllers.removeAll()
        application?.reply(toApplicationShouldTerminate: shouldTerminate)
    }

    private func orderedWindowControllers() -> [DocumentWindowController] {
        var controllers = NSDocumentController.shared.documents.compactMap { document in
            document.windowControllers.compactMap { $0 as? DocumentWindowController }.first
        }

        if let keyController = NSApp.keyWindow?.windowController as? DocumentWindowController,
           let keyIndex = controllers.firstIndex(where: { $0 === keyController }) {
            controllers.remove(at: keyIndex)
            controllers.insert(keyController, at: 0)
        }

        return controllers
    }
}
