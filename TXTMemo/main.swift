import AppKit

setenv("ApplePersistenceIgnoreState", "YES", 1)

MainActor.assumeIsolated {
    let application = NSApplication.shared
    let delegate = AppDelegate()

    application.delegate = delegate
    application.run()
}
