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
}
