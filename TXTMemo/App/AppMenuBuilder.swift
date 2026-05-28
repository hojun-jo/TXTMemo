import AppKit

enum AppMenuBuilder {
    static func buildMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = mainMenu.addItem(withTitle: "TXTMemo", action: nil, keyEquivalent: "")
        let fileMenuItem = mainMenu.addItem(withTitle: "File", action: nil, keyEquivalent: "")
        let editMenuItem = mainMenu.addItem(withTitle: "Edit", action: nil, keyEquivalent: "")

        appMenuItem.submenu = buildAppMenu()
        fileMenuItem.submenu = buildFileMenu()
        editMenuItem.submenu = buildEditMenu()

        NSApp.mainMenu = mainMenu
    }

    private static func buildAppMenu() -> NSMenu {
        let menu = NSMenu(title: "TXTMemo")

        menu.addItem(withTitle: "About TXTMemo", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings...", action: #selector(AppDelegate.showPreferences(_:)), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Hide TXTMemo", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        menu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h").keyEquivalentModifierMask = [.command, .option]
        menu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit TXTMemo", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        return menu
    }

    private static func buildFileMenu() -> NSMenu {
        let menu = NSMenu(title: "File")

        menu.addItem(withTitle: "New", action: #selector(NSDocumentController.newDocument(_:)), keyEquivalent: "n")
        menu.addItem(withTitle: "Open...", action: #selector(NSDocumentController.openDocument(_:)), keyEquivalent: "o")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

        let saveItem = menu.addItem(withTitle: "Save", action: #selector(NSDocument.save(_:)), keyEquivalent: "s")
        saveItem.keyEquivalentModifierMask = [.command]

        let saveAsItem = menu.addItem(withTitle: "Save As...", action: #selector(NSDocument.saveAs(_:)), keyEquivalent: "S")
        saveAsItem.keyEquivalentModifierMask = [.command, .shift]

        return menu
    }

    private static func buildEditMenu() -> NSMenu {
        let menu = NSMenu(title: "Edit")

        menu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        menu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        menu.addItem(.separator())
        let increaseItem = menu.addItem(withTitle: "Increase Font Size", action: #selector(DocumentWindowController.increaseFontSize(_:)), keyEquivalent: "+")
        increaseItem.keyEquivalentModifierMask = [.command]
        let decreaseItem = menu.addItem(withTitle: "Decrease Font Size", action: #selector(DocumentWindowController.decreaseFontSize(_:)), keyEquivalent: "-")
        decreaseItem.keyEquivalentModifierMask = [.command]
        let resetItem = menu.addItem(withTitle: "Reset Font Size", action: #selector(DocumentWindowController.resetFontSizeToDefault(_:)), keyEquivalent: "0")
        resetItem.keyEquivalentModifierMask = [.command]
        menu.addItem(.separator())
        menu.addItem(withTitle: "Auto Word Wrap", action: #selector(DocumentWindowController.toggleWrapEnabled(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        menu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        return menu
    }
}
