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

    func requestClose(context: CloseRequestContext, completion: @escaping (Bool) -> Void) {
        guard let windowController, let window = windowController.window else {
            completion(true)
            return
        }

        if isHandlingCloseRequest || window.attachedSheet != nil {
            window.makeKeyAndOrderFront(nil)
            completion(false)
            return
        }

        windowController.commitPendingEditorText()

        switch CloseDecisionEngine.decide(text: document.currentText(), isDocumentEdited: document.isDocumentEdited) {
        case .closeImmediately:
            completion(true)
        case .presentConfirmation:
            isHandlingCloseRequest = true
            presentConfirmationSheet(for: window, completion: completion)
        }
    }

    private func presentConfirmationSheet(for window: NSWindow, completion: @escaping (Bool) -> Void) {
        let sheetController = CloseConfirmationSheetController(documentName: document.displayName) { [weak self] action in
            self?.handleAction(action, in: window, completion: completion)
        }

        activeSheetController = sheetController
        sheetController.beginSheet(for: window)
    }

    private func handleAction(_ action: CloseConfirmationAction, in window: NSWindow, completion: @escaping (Bool) -> Void) {
        activeSheetController?.finish(on: window)
        activeSheetController = nil

        switch action {
        case .cancel:
            finishRequest(shouldClose: false, completion: completion)
        case .discard:
            finishRequest(shouldClose: true, completion: completion)
        case .save:
            saveDocument(forceSaveAs: false, in: window, completion: completion)
        case .saveAs:
            saveDocument(forceSaveAs: true, in: window, completion: completion)
        }
    }

    private func saveDocument(forceSaveAs: Bool, in window: NSWindow, completion: @escaping (Bool) -> Void) {
        document.saveForClosing(from: window, forceSaveAs: forceSaveAs) { [weak self] didSave in
            self?.finishRequest(shouldClose: didSave, completion: completion)
        }
    }

    private func finishRequest(shouldClose: Bool, completion: @escaping (Bool) -> Void) {
        isHandlingCloseRequest = false
        completion(shouldClose)
    }
}
