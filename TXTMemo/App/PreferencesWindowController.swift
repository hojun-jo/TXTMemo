import AppKit

@MainActor
final class PreferencesWindowController: NSWindowController, NSTextFieldDelegate {
    static let shared = PreferencesWindowController()

    private let settingsStore: SettingsStore
    private let fontSizeField = NSTextField(string: "")

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore

        let contentViewController = NSViewController()
        let window = NSWindow(contentViewController: contentViewController)
        window.title = "Settings"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 320, height: 120))
        window.isReleasedWhenClosed = false
        super.init(window: window)

        contentViewController.view = buildView()
        reloadValues()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init() {
        self.init(settingsStore: .shared)
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

        fontSizeField.alignment = .right
        fontSizeField.controlSize = .regular
        fontSizeField.delegate = self
        fontSizeField.target = self
        fontSizeField.action = #selector(commitFontSizeFieldAction(_:))

        let row = NSStackView(views: [label, fontSizeField, suffixLabel])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12

        fontSizeField.translatesAutoresizingMaskIntoConstraints = false
        fontSizeField.widthAnchor.constraint(equalToConstant: 56).isActive = true

        let container = NSView()
        let stack = NSStackView(views: [row])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
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
    }
}
