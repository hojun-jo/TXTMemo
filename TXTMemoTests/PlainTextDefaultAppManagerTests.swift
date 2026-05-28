import Foundation
import Testing
@testable import EditorCore

@MainActor
struct PlainTextDefaultAppManagerTests {
    @Test func reportsCurrentDefaultApplication() {
        let currentAppURL = URL(fileURLWithPath: "/Applications/TXTMemo.app")
        let otherAppURL = URL(fileURLWithPath: "/Applications/TextEdit.app")
        let manager = PlainTextDefaultAppManager(
            currentAppURL: currentAppURL,
            defaultApplicationURLProvider: { otherAppURL },
            setDefaultApplicationHandler: { _, _ in },
            applicationNameProvider: { url in
                url.deletingPathExtension().lastPathComponent
            }
        )

        let state = manager.currentState()

        #expect(state.currentDefaultApplicationName == "TextEdit")
        #expect(state.isCurrentApplicationDefault == false)
        #expect(state.statusText == "Current default app: TextEdit")
    }

    @Test func recognizesWhenCurrentApplicationIsAlreadyDefault() {
        let currentAppURL = URL(fileURLWithPath: "/Applications/TXTMemo.app")
        let manager = PlainTextDefaultAppManager(
            currentAppURL: currentAppURL,
            defaultApplicationURLProvider: { currentAppURL },
            setDefaultApplicationHandler: { _, _ in },
            applicationNameProvider: { _ in "TXTMemo" }
        )

        let state = manager.currentState()

        #expect(state.currentDefaultApplicationName == "TXTMemo")
        #expect(state.isCurrentApplicationDefault)
    }

    @Test func updatesStateAfterSettingCurrentApplicationAsDefault() async throws {
        let currentAppURL = URL(fileURLWithPath: "/Applications/TXTMemo.app")
        let otherAppURL = URL(fileURLWithPath: "/Applications/TextEdit.app")
        var currentDefaultAppURL = otherAppURL
        var didSetCurrentApplication = false
        var requestedAppURL: URL?
        let manager = PlainTextDefaultAppManager(
            currentAppURL: currentAppURL,
            defaultApplicationURLProvider: { currentDefaultAppURL },
            setDefaultApplicationHandler: { appURL, completion in
                didSetCurrentApplication = true
                requestedAppURL = appURL
                currentDefaultAppURL = currentAppURL
                completion(nil)
            },
            applicationNameProvider: { url in
                url.deletingPathExtension().lastPathComponent
            }
        )

        let state = try await manager.setCurrentApplicationAsDefault()

        #expect(didSetCurrentApplication)
        #expect(requestedAppURL == currentAppURL)
        #expect(state.currentDefaultApplicationName == "TXTMemo")
        #expect(state.isCurrentApplicationDefault)
    }

    @Test func prefersRegisteredApplicationURLWhenSettingDefault() async throws {
        let bundleAppURL = URL(fileURLWithPath: "/private/tmp/TXTMemo.app")
        let registeredAppURL = URL(fileURLWithPath: "/Users/hojun/Applications/TXTMemo.app")
        var requestedAppURL: URL?
        let manager = PlainTextDefaultAppManager(
            currentAppURL: bundleAppURL,
            registeredCurrentAppURLProvider: { registeredAppURL },
            defaultApplicationURLProvider: { registeredAppURL },
            setDefaultApplicationHandler: { appURL, completion in
                requestedAppURL = appURL
                completion(nil)
            },
            applicationNameProvider: { _ in "TXTMemo" }
        )

        _ = try await manager.setCurrentApplicationAsDefault()

        #expect(requestedAppURL == registeredAppURL)
        #expect(manager.currentState().isCurrentApplicationDefault)
    }

    @Test func surfacesDefaultApplicationUpdateErrors() async {
        struct SampleError: Error {}

        let manager = PlainTextDefaultAppManager(
            currentAppURL: URL(fileURLWithPath: "/Applications/TXTMemo.app"),
            defaultApplicationURLProvider: { nil },
            setDefaultApplicationHandler: { _, completion in
                completion(SampleError())
            },
            applicationNameProvider: { _ in "TXTMemo" }
        )

        do {
            _ = try await manager.setCurrentApplicationAsDefault()
            Issue.record("Expected SampleError")
        } catch is SampleError {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
