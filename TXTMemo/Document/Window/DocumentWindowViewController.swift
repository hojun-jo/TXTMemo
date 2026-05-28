import AppKit

final class DocumentWindowViewController: NSViewController, NSTextViewDelegate {
    private let document: NotepadDocument
    private let sessionController: EditorSessionController
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
        let scrollView = NSScrollView()

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
        applyDocumentText()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(textView)
    }

    func textDidChange(_ notification: Notification) {
        guard !isUpdatingFromDocument else { return }
        document.replaceText(with: textView.string)
    }

    func commitPendingEditorText() {
        view.window?.makeFirstResponder(nil)
        document.replaceText(with: textView.string)
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

    var currentFontSize: Int {
        sessionController.fontSize
    }

    private func applyDocumentText() {
        isUpdatingFromDocument = true
        textView.string = document.currentText()
        isUpdatingFromDocument = false
    }
}
