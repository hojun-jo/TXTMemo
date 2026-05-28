import Foundation

enum WrapLayoutController {
    struct Layout {
        let isHorizontallyResizable: Bool
        let widthTracksTextView: Bool
        let containerWidth: CGFloat
        let showsHorizontalScroller: Bool
        let autoresizesWidth: Bool
    }

    static func layout(wrapEnabled: Bool, contentWidth: CGFloat) -> Layout {
        if wrapEnabled {
            return Layout(
                isHorizontallyResizable: false,
                widthTracksTextView: true,
                containerWidth: contentWidth,
                showsHorizontalScroller: false,
                autoresizesWidth: true
            )
        }

        return Layout(
            isHorizontallyResizable: true,
            widthTracksTextView: false,
            containerWidth: .greatestFiniteMagnitude,
            showsHorizontalScroller: true,
            autoresizesWidth: false
        )
    }
}
