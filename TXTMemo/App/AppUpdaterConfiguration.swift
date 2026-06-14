import Foundation

struct AppUpdaterConfiguration: Equatable {
  let feedURL: URL
  let publicEDKey: String

  static func load(from bundle: Bundle) -> AppUpdaterConfiguration? {
    parse(infoDictionary: bundle.infoDictionary ?? [:])
  }

  static func parse(infoDictionary: [String: Any]) -> AppUpdaterConfiguration? {
    guard let feedURLString = infoDictionary["SUFeedURL"] as? String,
      let publicEDKey = infoDictionary["SUPublicEDKey"] as? String
    else {
      return nil
    }

    let trimmedFeedURLString = feedURLString.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedPublicEDKey = publicEDKey.trimmingCharacters(in: .whitespacesAndNewlines)
    let requiresSignedFeed = infoDictionary["SURequireSignedFeed"] as? Bool ?? false
    let verifiesUpdateBeforeExtraction =
      infoDictionary["SUVerifyUpdateBeforeExtraction"] as? Bool ?? false

    guard !trimmedFeedURLString.isEmpty,
      !trimmedPublicEDKey.isEmpty,
      !trimmedPublicEDKey.hasPrefix("REPLACE_WITH_"),
      requiresSignedFeed,
      verifiesUpdateBeforeExtraction,
      let feedURL = URL(string: trimmedFeedURLString),
      isSupportedFeedURL(feedURL)
    else {
      return nil
    }

    return AppUpdaterConfiguration(feedURL: feedURL, publicEDKey: trimmedPublicEDKey)
  }

  private static func isSupportedFeedURL(_ feedURL: URL) -> Bool {
    if feedURL.isFileURL {
      return true
    }

    return feedURL.scheme == "https" && !(feedURL.host?.isEmpty ?? true)
  }
}
