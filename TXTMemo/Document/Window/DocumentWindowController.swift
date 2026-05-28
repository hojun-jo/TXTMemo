import AppKit

@MainActor
final class DocumentWindowController: NSWindowController, NSWindowDelegate, NSToolbarDelegate, NSTextFieldDelegate, NSMenuItemValidation {
    private enum Layout {
        static let controlHeight: CGFloat = 28
        static let saveButtonWidth: CGFloat = 56
        static let fontSizeFieldWidth: CGFloat = 56
        static let toolbarButtonWidth: CGFloat = 32
        static let wrapButtonWidth: CGFloat = 72
    }

    private enum ToolbarItemIdentifier {
        static let save = NSToolbarItem.Identifier("save")
        static let decreaseFontSize = NSToolbarItem.Identifier("decreaseFontSize")
        static let currentFontSize = NSToolbarItem.Identifier("currentFontSize")
        static let increaseFontSize = NSToolbarItem.Identifier("increaseFontSize")
        static let wrapToggle = NSToolbarItem.Identifier("wrapToggle")
    }

    private static let defaultToolbarItemIdentifiers: [NSToolbarItem.Identifier] = [
        ToolbarItemIdentifier.save,
        ToolbarItemIdentifier.decreaseFontSize,
        ToolbarItemIdentifier.currentFontSize,
        ToolbarItemIdentifier.increaseFontSize,
        ToolbarItemIdentifier.wrapToggle,
        .flexibleSpace
    ]

    private lazy var closeCoordinator = CloseWorkflowCoordinator(document: documentRef, windowController: self)
    private let documentRef: NotepadDocument
    private let sessionController = EditorSessionController()
    private weak var documentViewController: DocumentWindowViewController?
    private var bypassesCloseConfirmation = false
    private let saveButton = NSButton(title: "Save", target: nil, action: nil)
    private let decreaseFontSizeButton = NSButton(title: "A-", target: nil, action: nil)
    private let increaseFontSizeButton = NSButton(title: "A+", target: nil, action: nil)
    private let fontSizeField = NSTextField(string: "")
    private let wrapToggleButton = NSButton(checkboxWithTitle: "Wrap", target: nil, action: nil)
    private var fontSizeObserverID: UUID?
    private var wrapObserverID: UUID?
    private var hasConfiguredToolbarControls = false

    init(document: NotepadDocument) {
        let viewController = DocumentWindowViewController(document: document, sessionController: sessionController)
        let window = NSWindow(contentViewController: viewController)

        self.documentRef = document
        self.documentViewController = viewController

        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 800, height: 600))
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.isReleasedWhenClosed = false

        super.init(window: window)

        shouldCloseDocument = true
        window.delegate = self
        window.toolbar = buildToolbar()
        synchronizeWindowTitleWithDocumentName()
        bindSessionState()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func windowTitle(forDocumentDisplayName displayName: String) -> String {
        guard let document else { return displayName }
        return WindowTitleFormatter.format(displayName: displayName, hasUnsavedChanges: document.isDocumentEdited)
    }

    override func synchronizeWindowTitleWithDocumentName() {
        super.synchronizeWindowTitleWithDocumentName()
        refreshToolbarUI()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard !bypassesCloseConfirmation else { return true }

        requestClose(for: .windowClose) { [weak self] shouldClose in
            if shouldClose {
                self?.forceCloseWindow()
            }
        }

        return false
    }

    func requestClose(for context: CloseRequestContext, completion: @escaping (Bool) -> Void) {
        closeCoordinator.requestClose(context: context, completion: completion)
    }

    func forceCloseWindow() {
        guard let window else { return }

        bypassesCloseConfirmation = true
        window.performClose(nil)
        bypassesCloseConfirmation = false
    }

    func commitPendingEditorText() {
        documentViewController?.commitPendingEditorText()
    }

    @objc func saveDocument(_ sender: Any?) {
        prepareToSave()
        documentRef.save(sender)
    }

    @objc func saveDocumentAs(_ sender: Any?) {
        prepareToSave()
        documentRef.saveAs(sender)
    }

    @objc func increaseFontSize(_ sender: Any?) {
        documentViewController?.increaseFontSize()
    }

    @objc func decreaseFontSize(_ sender: Any?) {
        documentViewController?.decreaseFontSize()
    }

    @objc func resetFontSizeToDefault(_ sender: Any?) {
        documentViewController?.resetFontSizeToDefault()
    }

    @objc func toggleWrapEnabled(_ sender: Any?) {
        documentViewController?.toggleWrapEnabled()
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        commitFontSizeField()
    }

    @objc func commitFontSizeFieldAction(_ sender: Any?) {
        commitFontSizeField()
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(saveDocument(_:)):
            return documentRef.isDocumentEdited
        case #selector(saveDocumentAs(_:)):
            return true
        case #selector(increaseFontSize(_:)):
            return currentFontSize < FontSizePolicy.maximum
        case #selector(decreaseFontSize(_:)):
            return currentFontSize > FontSizePolicy.minimum
        case #selector(resetFontSizeToDefault(_:)):
            return true
        case #selector(toggleWrapEnabled(_:)):
            menuItem.state = isWrapEnabled ? .on : .off
            return true
        default:
            return true
        }
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        Self.defaultToolbarItemIdentifiers
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        Self.defaultToolbarItemIdentifiers
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        switch itemIdentifier {
        case ToolbarItemIdentifier.save:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.view = saveButton
            item.label = "Save"
            item.paletteLabel = "Save"
            return item
        case ToolbarItemIdentifier.decreaseFontSize:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.view = decreaseFontSizeButton
            item.label = "A-"
            item.paletteLabel = "Decrease Font Size"
            return item
        case ToolbarItemIdentifier.currentFontSize:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.view = fontSizeField
            item.label = "Font Size"
            return item
        case ToolbarItemIdentifier.increaseFontSize:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.view = increaseFontSizeButton
            item.label = "A+"
            item.paletteLabel = "Increase Font Size"
            return item
        case ToolbarItemIdentifier.wrapToggle:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.view = wrapToggleButton
            item.label = "Wrap"
            return item
        default:
            return nil
        }
    }

    private var currentFontSize: Int {
        documentViewController?.currentFontSize ?? sessionController.fontSize
    }

    private var isWrapEnabled: Bool {
        documentViewController?.isWrapEnabled ?? sessionController.wrapEnabled
    }

    private func bindSessionState() {
        fontSizeObserverID = sessionController.addFontSizeObserver { [weak self] fontSize in
            self?.fontSizeField.stringValue = String(fontSize)
            self?.refreshToolbarUI()
        }
        wrapObserverID = sessionController.addWrapObserver { [weak self] wrapEnabled in
            self?.wrapToggleButton.state = wrapEnabled ? .on : .off
            self?.refreshToolbarUI()
        }
    }

    private func buildToolbar() -> NSToolbar {
        configureToolbarControlsIfNeeded()

        let toolbar = NSToolbar(identifier: "DocumentToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .default
        toolbar.allowsUserCustomization = false
        return toolbar
    }

    private func configureToolbarControlsIfNeeded() {
        guard !hasConfiguredToolbarControls else { return }

        configureToolbarButton(saveButton, width: Layout.saveButtonWidth, action: #selector(saveDocument(_:)))
        configureToolbarButton(decreaseFontSizeButton, width: Layout.toolbarButtonWidth, action: #selector(decreaseFontSize(_:)))
        configureToolbarButton(increaseFontSizeButton, width: Layout.toolbarButtonWidth, action: #selector(increaseFontSize(_:)))

        fontSizeField.alignment = .right
        fontSizeField.controlSize = .regular
        fontSizeField.delegate = self
        fontSizeField.target = self
        fontSizeField.action = #selector(commitFontSizeFieldAction(_:))
        fontSizeField.isBordered = true
        fontSizeField.isBezeled = true
        fontSizeField.frame = NSRect(x: 0, y: 0, width: Layout.fontSizeFieldWidth, height: Layout.controlHeight)
        fontSizeField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fontSizeField.widthAnchor.constraint(equalToConstant: Layout.fontSizeFieldWidth),
            fontSizeField.heightAnchor.constraint(equalToConstant: Layout.controlHeight)
        ])

        wrapToggleButton.target = self
        wrapToggleButton.action = #selector(toggleWrapEnabled(_:))
        wrapToggleButton.bezelStyle = .texturedRounded
        wrapToggleButton.setButtonType(.toggle)
        wrapToggleButton.frame = NSRect(x: 0, y: 0, width: Layout.wrapButtonWidth, height: Layout.controlHeight)
        wrapToggleButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wrapToggleButton.widthAnchor.constraint(equalToConstant: Layout.wrapButtonWidth),
            wrapToggleButton.heightAnchor.constraint(equalToConstant: Layout.controlHeight)
        ])

        hasConfiguredToolbarControls = true
        refreshToolbarControlStates()
    }

    private func configureToolbarButton(_ button: NSButton, width: CGFloat, action: Selector) {
        button.target = self
        button.action = action
        button.bezelStyle = .texturedRounded
        button.frame = NSRect(x: 0, y: 0, width: width, height: Layout.controlHeight)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: width),
            button.heightAnchor.constraint(equalToConstant: Layout.controlHeight)
        ])
    }

    func prepareToSave() {
        documentViewController?.commitPendingEditorText(preservingEditorFocus: true)
    }

    private func refreshToolbarUI() {
        refreshToolbarControlStates()
        window?.toolbar?.validateVisibleItems()
    }

    private func refreshToolbarControlStates() {
        saveButton.isEnabled = documentRef.isDocumentEdited
        decreaseFontSizeButton.isEnabled = currentFontSize > FontSizePolicy.minimum
        increaseFontSizeButton.isEnabled = currentFontSize < FontSizePolicy.maximum
    }

    private func commitFontSizeField() {
        documentViewController?.commitFontSizeInput(fontSizeField.stringValue)
        fontSizeField.stringValue = String(currentFontSize)
    }
}
