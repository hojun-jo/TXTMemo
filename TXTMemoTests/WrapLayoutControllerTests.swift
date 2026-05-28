import Foundation
import Testing
@testable import EditorCore

struct WrapLayoutControllerTests {
    @Test func wrappedLayoutTracksVisibleWidth() {
        let layout = WrapLayoutController.layout(wrapEnabled: true, contentWidth: 480)

        #expect(layout.isHorizontallyResizable == false)
        #expect(layout.widthTracksTextView)
        #expect(layout.containerWidth == 480)
        #expect(layout.showsHorizontalScroller == false)
        #expect(layout.autoresizesWidth)
    }

    @Test func unwrappedLayoutEnablesHorizontalScrolling() {
        let layout = WrapLayoutController.layout(wrapEnabled: false, contentWidth: 480)

        #expect(layout.isHorizontallyResizable)
        #expect(layout.widthTracksTextView == false)
        #expect(layout.containerWidth == .greatestFiniteMagnitude)
        #expect(layout.showsHorizontalScroller)
        #expect(layout.autoresizesWidth == false)
    }
}
