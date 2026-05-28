import AppKit

final class NotepadTextView: NSTextView {
    private var currentFontSize = FontSizePolicy.defaultSize
    private var isWrapEnabled = true

    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        let textContainer = container ?? NSTextContainer()
        let layoutManager = NSLayoutManager()
        let textStorage = NSTextStorage()

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        super.init(frame: frameRect, textContainer: textContainer)

        isRichText = false
        importsGraphics = false
        allowsUndo = true
        isContinuousSpellCheckingEnabled = false
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticTextReplacementEnabled = false
        isAutomaticSpellingCorrectionEnabled = false
        font = NSFont.monospacedSystemFont(ofSize: CGFloat(currentFontSize), weight: .regular)
        textColor = .labelColor
        backgroundColor = .textBackgroundColor
        insertionPointColor = .labelColor
        isHorizontallyResizable = false
        usesFindBar = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func paste(_ sender: Any?) {
        pasteAsPlainText(sender)
    }

    func applyFontSize(_ size: Int) {
        currentFontSize = FontSizePolicy.clamp(size)
        font = NSFont.monospacedSystemFont(ofSize: CGFloat(currentFontSize), weight: .regular)
    }

    func applyWrapEnabled(_ enabled: Bool, in scrollView: NSScrollView) {
        guard let textContainer else { return }

        isWrapEnabled = enabled
        let contentWidth = scrollView.contentSize.width

        if enabled {
            isHorizontallyResizable = false
            autoresizingMask = [.width]
            textContainer.widthTracksTextView = true
            textContainer.containerSize = NSSize(width: contentWidth, height: .greatestFiniteMagnitude)
            setFrameSize(NSSize(width: contentWidth, height: frame.height))
            scrollView.hasHorizontalScroller = false
        } else {
            isHorizontallyResizable = true
            autoresizingMask = []
            textContainer.widthTracksTextView = false
            textContainer.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            scrollView.hasHorizontalScroller = true
            sizeToFit()
        }
    }
}
