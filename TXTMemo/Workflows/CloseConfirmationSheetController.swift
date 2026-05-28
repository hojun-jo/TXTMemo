import AppKit

enum CloseConfirmationAction {
    case save
    case saveAs
    case cancel
    case discard
}

@MainActor
final class CloseConfirmationSheetController: NSWindowController {
    init(documentName: String, onAction: @escaping (CloseConfirmationAction) -> Void) {

        let contentViewController = CloseConfirmationViewController(documentName: documentName, onAction: onAction)
        let window = NSWindow(contentViewController: contentViewController)

        window.styleMask = [.titled]
        window.title = ""
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func beginSheet(for parentWindow: NSWindow) {
        parentWindow.beginSheet(window!)
    }

    func finish(on parentWindow: NSWindow) {
        parentWindow.endSheet(window!)
    }
}

private final class CloseConfirmationViewController: NSViewController {
    private let documentName: String
    private let onAction: (CloseConfirmationAction) -> Void
    private weak var saveButton: NSButton?
    private var hasSentAction = false

    init(documentName: String, onAction: @escaping (CloseConfirmationAction) -> Void) {
        self.documentName = documentName
        self.onAction = onAction
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let rootView = NSView()
        rootView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: "\(documentName)의 변경 사항을 저장할까요?")
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.maximumNumberOfLines = 2

        let messageLabel = NSTextField(labelWithString: "저장하지 않고 닫으면 마지막 저장 이후 변경 사항이 사라집니다.")
        messageLabel.textColor = .secondaryLabelColor
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.maximumNumberOfLines = 3

        let discardButton = NSButton(title: "저장하지 않고 종료", target: self, action: #selector(handleDiscard))
        if #available(macOS 11.0, *) {
            discardButton.hasDestructiveAction = true
        }

        let cancelButton = NSButton(title: "취소", target: self, action: #selector(handleCancel))
        cancelButton.keyEquivalent = "\u{1b}"

        let saveAsButton = NSButton(title: "다른 이름으로 저장", target: self, action: #selector(handleSaveAs))

        let saveButton = NSButton(title: "저장", target: self, action: #selector(handleSave))
        saveButton.keyEquivalent = "\r"
        saveButton.bezelStyle = .rounded
        self.saveButton = saveButton

        let headerStack = NSStackView(views: [titleLabel, messageLabel])
        headerStack.orientation = .vertical
        headerStack.alignment = .leading
        headerStack.spacing = 8

        let rightButtons = NSStackView(views: [cancelButton, saveAsButton, saveButton])
        rightButtons.orientation = .horizontal
        rightButtons.spacing = 8
        rightButtons.alignment = .centerY

        let buttonRow = NSStackView(views: [discardButton, NSView(), rightButtons])
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY

        let contentStack = NSStackView(views: [headerStack, buttonRow])
        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        rootView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: rootView.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: rootView.bottomAnchor, constant: -24),
            rootView.widthAnchor.constraint(greaterThanOrEqualToConstant: 520),
        ])

        view = rootView
        preferredContentSize = NSSize(width: 560, height: 170)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.defaultButtonCell = saveButton?.cell as? NSButtonCell
        view.window?.initialFirstResponder = saveButton
        view.window?.makeFirstResponder(saveButton)
    }

    @objc
    private func handleSave() {
        sendAction(.save)
    }

    @objc
    private func handleSaveAs() {
        sendAction(.saveAs)
    }

    @objc
    private func handleCancel() {
        sendAction(.cancel)
    }

    @objc
    private func handleDiscard() {
        sendAction(.discard)
    }

    private func sendAction(_ action: CloseConfirmationAction) {
        guard !hasSentAction else { return }
        hasSentAction = true
        onAction(action)
    }
}
