import AppKit

final class NotepadTextView: NSTextView {
    private var currentFontSize = FontSizePolicy.defaultSize

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

        let layout = WrapLayoutController.layout(wrapEnabled: enabled, contentWidth: scrollView.contentSize.width)

        isHorizontallyResizable = layout.isHorizontallyResizable
        autoresizingMask = layout.autoresizesWidth ? [.width] : []
        textContainer.widthTracksTextView = layout.widthTracksTextView
        textContainer.containerSize = NSSize(width: layout.containerWidth, height: CGFloat.greatestFiniteMagnitude)
        scrollView.hasHorizontalScroller = layout.showsHorizontalScroller

        if enabled {
            setFrameSize(NSSize(width: layout.containerWidth, height: frame.height))
        } else {
            maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            sizeToFit()
        }
    }
}
