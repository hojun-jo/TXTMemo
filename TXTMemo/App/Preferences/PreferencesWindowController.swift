import AppKit

@MainActor
final class PreferencesWindowController: NSWindowController, NSTextFieldDelegate {
    private let settingsStore: SettingsStore
    private let defaultAppManager: PlainTextDefaultAppManager
    private let fontSizeField = NSTextField(string: "")
    private let defaultAppStatusLabel = NSTextField(labelWithString: "")
    private let defaultAppButton = NSButton(title: "", target: nil, action: nil)
    private var isUpdatingDefaultApp = false

    init(
        settingsStore: SettingsStore,
        defaultAppManager: PlainTextDefaultAppManager? = nil
    ) {
        self.settingsStore = settingsStore
        self.defaultAppManager = defaultAppManager ?? PlainTextDefaultAppManager()

        let contentViewController = NSViewController()
        let window = NSWindow(contentViewController: contentViewController)
        window.title = "Settings"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 520, height: 200))
        window.isReleasedWhenClosed = false
        super.init(window: window)

        contentViewController.view = buildView()
        reloadValues()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showWindowAndFocus() {
        reloadValues()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        window?.center()
        window?.makeFirstResponder(fontSizeField)
        NSApp.activate(ignoringOtherApps: true)
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        commitFontSizeField()
    }

    @objc func commitFontSizeFieldAction(_ sender: Any?) {
        commitFontSizeField()
    }

    private func buildView() -> NSView {
        let label = NSTextField(labelWithString: "Default font size")
        let suffixLabel = NSTextField(labelWithString: "pt")
        let defaultAppLabel = NSTextField(labelWithString: "Default plain text app")

        fontSizeField.alignment = .right
        fontSizeField.controlSize = .regular
        fontSizeField.delegate = self
        fontSizeField.target = self
        fontSizeField.action = #selector(commitFontSizeFieldAction(_:))

        defaultAppStatusLabel.lineBreakMode = .byWordWrapping
        defaultAppStatusLabel.textColor = .secondaryLabelColor
        defaultAppStatusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        defaultAppStatusLabel.usesSingleLineMode = false
        defaultAppStatusLabel.cell?.wraps = true

        defaultAppButton.target = self
        defaultAppButton.action = #selector(setDefaultPlainTextApp(_:))

        let row = NSStackView(views: [label, fontSizeField, suffixLabel])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12

        let defaultAppSection = NSStackView(views: [defaultAppLabel, defaultAppStatusLabel, defaultAppButton])
        defaultAppSection.orientation = .vertical
        defaultAppSection.alignment = .leading
        defaultAppSection.spacing = 8

        fontSizeField.translatesAutoresizingMaskIntoConstraints = false
        fontSizeField.widthAnchor.constraint(equalToConstant: 56).isActive = true
        defaultAppStatusLabel.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        let stack = NSStackView(views: [row, defaultAppSection])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -20),
            defaultAppStatusLabel.widthAnchor.constraint(lessThanOrEqualTo: stack.widthAnchor)
        ])

        return container
    }

    @objc func setDefaultPlainTextApp(_ sender: Any?) {
        guard !isUpdatingDefaultApp else { return }

        isUpdatingDefaultApp = true
        refreshDefaultAppControls()

        Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                _ = try await defaultAppManager.setCurrentApplicationAsDefault()
            } catch {
                presentDefaultAppUpdateErrorIfNeeded(error)
            }

            isUpdatingDefaultApp = false
            refreshDefaultAppControls()
        }
    }

    private func commitFontSizeField() {
        guard let parsed = Int(fontSizeField.stringValue), !fontSizeField.stringValue.isEmpty else {
            reloadValues()
            return
        }

        settingsStore.defaultFontSize = parsed
        reloadValues()
    }

    private func reloadValues() {
        fontSizeField.stringValue = String(settingsStore.defaultFontSize)
        refreshDefaultAppControls()
    }

    private func refreshDefaultAppControls() {
        let state = defaultAppManager.currentState()

        defaultAppStatusLabel.stringValue = state.statusText

        if isUpdatingDefaultApp {
            defaultAppButton.title = "Updating..."
            defaultAppButton.isEnabled = false
            return
        }

        if state.isCurrentApplicationDefault {
            defaultAppButton.title = "Already Default for Plain Text"
            defaultAppButton.isEnabled = false
            return
        }

        defaultAppButton.title = "Set as Default for Plain Text"
        defaultAppButton.isEnabled = true
    }

    private func presentDefaultAppUpdateErrorIfNeeded(_ error: Error) {
        let nsError = error as NSError

        if nsError.domain == NSCocoaErrorDomain, nsError.code == NSUserCancelledError {
            return
        }

        AlertPresenter.present(error)
    }
}
