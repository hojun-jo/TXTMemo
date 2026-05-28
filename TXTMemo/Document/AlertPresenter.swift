import AppKit

@MainActor
enum AlertPresenter {
    static func present(_ error: Error) {
        NSApp.presentError(error)
    }
}
