import AppKit

final class DocumentWindowViewController: NSViewController, NSTextViewDelegate {
    private let document: NotepadDocument
    private let sessionController: EditorSessionController
    private let scrollView = NSScrollView()
    private let textView = NotepadTextView(frame: .zero, textContainer: nil)
    private var isUpdatingFromDocument = false

    init(document: NotepadDocument, sessionController: EditorSessionController) {
        self.document = document
        self.sessionController = sessionController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.documentView = textView

        textView.delegate = self
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        view = scrollView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        sessionController.addFontSizeObserver { [weak self] fontSize in
            self?.textView.applyFontSize(fontSize)
        }
        sessionController.addWrapObserver { [weak self] wrapEnabled in
            guard let self else { return }
            self.textView.applyWrapEnabled(wrapEnabled, in: self.scrollView)
        }
        applyDocumentText()
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        if sessionController.wrapEnabled {
            textView.applyWrapEnabled(true, in: scrollView)
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(textView)
    }

    func textDidChange(_ notification: Notification) {
        guard !isUpdatingFromDocument else { return }
        document.replaceText(with: textView.string)
    }

    @objc func undo(_ sender: Any?) {
        textView.undoManager?.undo()
        synchronizeDocumentAfterUndoRedo()
    }

    @objc func redo(_ sender: Any?) {
        textView.undoManager?.redo()
        synchronizeDocumentAfterUndoRedo()
    }

    func commitPendingEditorText(preservingEditorFocus: Bool = false) {
        let window = view.window
        let shouldRestoreEditorFocus = preservingEditorFocus && window?.firstResponder === textView

        window?.makeFirstResponder(nil)
        document.replaceText(with: textView.string)

        if shouldRestoreEditorFocus {
            window?.makeFirstResponder(textView)
        }
    }

    func increaseFontSize() {
        sessionController.increaseFontSize()
    }

    func decreaseFontSize() {
        sessionController.decreaseFontSize()
    }

    func resetFontSizeToDefault() {
        sessionController.resetFontSizeToDefault()
    }

    func commitFontSizeInput(_ value: String?) {
        sessionController.commitFontSizeInput(value)
    }

    func toggleWrapEnabled() {
        sessionController.toggleWrapEnabled()
    }

    var isWrapEnabled: Bool {
        sessionController.wrapEnabled
    }

    var currentFontSize: Int {
        sessionController.fontSize
    }

    private func applyDocumentText() {
        isUpdatingFromDocument = true
        textView.string = document.currentText()
        isUpdatingFromDocument = false
    }

    private func synchronizeDocumentAfterUndoRedo() {
        guard !isUpdatingFromDocument else { return }
        document.recomputeEditedState(for: textView.string)
    }
}
