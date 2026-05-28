import Foundation
import Testing
@testable import EditorCore

struct TextFileCodecTests {
    @Test func readsUTF8Text() throws {
        let data = Data("hello".utf8)

        let decoded = try TextFileCodec.readText(from: data)

        #expect(decoded == "hello")
    }

    @Test func fallsBackToDetectedPlainTextEncoding() throws {
        let data = Data([0x63, 0x61, 0x66, 0xE9])

        let decoded = try TextFileCodec.readText(from: data)

        #expect(decoded == "café")
    }

    @Test func rejectsUndecodableBinaryData() {
        let data = Data([0x00, 0xFF, 0x00, 0xFF])

        #expect(throws: CocoaError.self) {
            try TextFileCodec.readText(from: data)
        }
    }

    @Test func writesUTF8WithoutBom() throws {
        let data = try TextFileCodec.writeUTF8Text("memo")

        #expect(Array(data.prefix(3)) != [0xEF, 0xBB, 0xBF])
        #expect(String(data: data, encoding: .utf8) == "memo")
    }
}
