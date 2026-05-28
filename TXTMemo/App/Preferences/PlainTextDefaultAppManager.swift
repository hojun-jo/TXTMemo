import AppKit
import UniformTypeIdentifiers

@MainActor
struct PlainTextDefaultAppState: Equatable {
    let currentDefaultApplicationName: String?
    let isCurrentApplicationDefault: Bool

    var statusText: String {
        if let currentDefaultApplicationName {
            return "Current default app: \(currentDefaultApplicationName)"
        }

        return "Current default app: Not set"
    }
}

@MainActor
final class PlainTextDefaultAppManager {
    typealias SetDefaultApplicationCompletion = @Sendable (Error?) -> Void
    typealias SetDefaultApplicationHandler = (URL, @escaping SetDefaultApplicationCompletion) -> Void

    private let currentAppURL: URL
    private let defaultApplicationURLProvider: () -> URL?
    private let setDefaultApplicationHandler: SetDefaultApplicationHandler
    private let applicationNameProvider: (URL) -> String

    init(
        workspace: NSWorkspace = .shared,
        bundle: Bundle = .main,
        currentAppURL: URL? = nil,
        registeredCurrentAppURLProvider: (() -> URL?)? = nil,
        defaultApplicationURLProvider: (() -> URL?)? = nil,
        setDefaultApplicationHandler: SetDefaultApplicationHandler? = nil,
        applicationNameProvider: ((URL) -> String)? = nil
    ) {
        let fallbackCurrentAppURL = (currentAppURL ?? bundle.bundleURL).standardizedFileURL
        let resolvedBundleIdentifier = bundle.bundleIdentifier
        let resolvedRegisteredCurrentAppURLProvider = registeredCurrentAppURLProvider ?? {
            guard let resolvedBundleIdentifier else { return nil }
            return workspace.urlForApplication(withBundleIdentifier: resolvedBundleIdentifier)
        }
        let resolvedCurrentAppURL = resolvedRegisteredCurrentAppURLProvider()?.standardizedFileURL ?? fallbackCurrentAppURL

        self.currentAppURL = resolvedCurrentAppURL
        self.defaultApplicationURLProvider = defaultApplicationURLProvider ?? {
            workspace.urlForApplication(toOpen: .plainText)
        }
        self.setDefaultApplicationHandler = setDefaultApplicationHandler ?? { appURL, completion in
            workspace.setDefaultApplication(
                at: appURL,
                toOpen: .plainText,
                completion: completion
            )
        }
        self.applicationNameProvider = applicationNameProvider ?? Self.applicationName(for:)
    }

    func currentState() -> PlainTextDefaultAppState {
        guard let defaultApplicationURL = defaultApplicationURLProvider() else {
            return PlainTextDefaultAppState(
                currentDefaultApplicationName: nil,
                isCurrentApplicationDefault: false
            )
        }

        return PlainTextDefaultAppState(
            currentDefaultApplicationName: applicationNameProvider(defaultApplicationURL),
            isCurrentApplicationDefault: defaultApplicationURL.standardizedFileURL == currentAppURL.standardizedFileURL
        )
    }

    func setCurrentApplicationAsDefault() async throws -> PlainTextDefaultAppState {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            setDefaultApplicationHandler(currentAppURL) { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume()
            }
        }

        return currentState()
    }

    private static func applicationName(for url: URL) -> String {
        let bundle = Bundle(url: url)

        if let displayName = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
           !displayName.isEmpty {
            return displayName
        }

        if let name = bundle?.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String,
           !name.isEmpty {
            return name
        }

        return url.deletingPathExtension().lastPathComponent
    }
}
