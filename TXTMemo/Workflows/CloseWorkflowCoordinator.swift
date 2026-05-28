import AppKit
import UniformTypeIdentifiers

enum CloseRequestContext {
    case windowClose
    case appTermination
}

@MainActor
final class CloseWorkflowCoordinator {
    private unowned let document: NotepadDocument
    private weak var windowController: DocumentWindowController?
    private var activeSheetController: CloseConfirmationSheetController?
    private var isHandlingCloseRequest = false

    init(document: NotepadDocument, windowController: DocumentWindowController) {
        self.document = document
        self.windowController = windowController
    }

    func requestClose(context: CloseRequestContext) async -> Bool {
        guard let windowController, let window = windowController.window else {
            return true
        }

        if isHandlingCloseRequest || window.attachedSheet != nil {
            window.makeKeyAndOrderFront(nil)
            return false
        }

        windowController.commitPendingEditorText()

        switch CloseDecisionEngine.decide(text: document.currentText(), isDocumentEdited: document.isDocumentEdited) {
        case .closeImmediately:
            return true
        case .presentConfirmation:
            isHandlingCloseRequest = true
            return await presentConfirmationSheet(for: window)
        }
    }

    private func presentConfirmationSheet(for window: NSWindow) async -> Bool {
        await withCheckedContinuation { continuation in
            let sheetController = CloseConfirmationSheetController(documentName: document.displayName) { [weak self] action in
                guard let self else {
                    continuation.resume(returning: false)
                    return
                }

                Task { @MainActor in
                    let shouldClose = await self.handleAction(action, in: window)
                    continuation.resume(returning: shouldClose)
                }
            }

            activeSheetController = sheetController
            sheetController.beginSheet(for: window)
        }
    }

    private func handleAction(_ action: CloseConfirmationAction, in window: NSWindow) async -> Bool {
        activeSheetController?.finish(on: window)
        activeSheetController = nil

        switch action {
        case .cancel:
            return finishRequest(shouldClose: false)
        case .discard:
            return finishRequest(shouldClose: true)
        case .save:
            return await saveDocument(forceSaveAs: false, in: window)
        case .saveAs:
            return await saveDocument(forceSaveAs: true, in: window)
        }
    }

    private func saveDocument(forceSaveAs: Bool, in window: NSWindow) async -> Bool {
        let result = await document.saveForClosing(from: window, forceSaveAs: forceSaveAs)
        return finishRequest(shouldClose: result.shouldClose)
    }

    private func finishRequest(shouldClose: Bool) -> Bool {
        isHandlingCloseRequest = false
        return shouldClose
    }
}
