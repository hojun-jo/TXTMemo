import Foundation

enum TextFileCodec {
    nonisolated
    static func readText(from data: Data) throws -> String {
        if let string = String(data: data, encoding: .utf8) {
            return string
        }

        var detectedString: NSString?
        var usedLossyConversion = ObjCBool(false)
        let rawEncoding = NSString.stringEncoding(
            for: data,
            encodingOptions: [:],
            convertedString: &detectedString,
            usedLossyConversion: &usedLossyConversion
        )

        guard
            rawEncoding != 0,
            usedLossyConversion.boolValue == false,
            let detectedString
        else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }

        return detectedString as String
    }

    nonisolated
    static func writeUTF8Text(_ string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }

        return data
    }
}
