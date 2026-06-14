import Foundation
import Testing

@testable import EditorCore

struct AppUpdaterConfigurationTests {
  @Test func acceptsSignedFeedConfiguration() {
    let configuration = AppUpdaterConfiguration.parse(infoDictionary: [
      "SUFeedURL": "https://example.com/appcast.xml",
      "SUPublicEDKey": "real-public-key",
      "SURequireSignedFeed": true,
      "SUVerifyUpdateBeforeExtraction": true,
    ])

    #expect(configuration?.feedURL == URL(string: "https://example.com/appcast.xml"))
    #expect(configuration?.publicEDKey == "real-public-key")
  }

  @Test func rejectsPlaceholderPublicKey() {
    let configuration = AppUpdaterConfiguration.parse(infoDictionary: [
      "SUFeedURL": "https://example.com/appcast.xml",
      "SUPublicEDKey": "REPLACE_WITH_SPARKLE_PUBLIC_ED_KEY",
      "SURequireSignedFeed": true,
      "SUVerifyUpdateBeforeExtraction": true,
    ])

    #expect(configuration == nil)
  }

  @Test func rejectsInvalidFeedURL() {
    let configuration = AppUpdaterConfiguration.parse(infoDictionary: [
      "SUFeedURL": "not a url",
      "SUPublicEDKey": "real-public-key",
      "SURequireSignedFeed": true,
      "SUVerifyUpdateBeforeExtraction": true,
    ])

    #expect(configuration == nil)
  }

  @Test func rejectsUnsignedFeedConfiguration() {
    let configuration = AppUpdaterConfiguration.parse(infoDictionary: [
      "SUFeedURL": "https://example.com/appcast.xml",
      "SUPublicEDKey": "real-public-key",
      "SURequireSignedFeed": false,
      "SUVerifyUpdateBeforeExtraction": true,
    ])

    #expect(configuration == nil)
  }

  @Test func rejectsMissingArchiveVerification() {
    let configuration = AppUpdaterConfiguration.parse(infoDictionary: [
      "SUFeedURL": "https://example.com/appcast.xml",
      "SUPublicEDKey": "real-public-key",
      "SURequireSignedFeed": true,
      "SUVerifyUpdateBeforeExtraction": false,
    ])

    #expect(configuration == nil)
  }
}
