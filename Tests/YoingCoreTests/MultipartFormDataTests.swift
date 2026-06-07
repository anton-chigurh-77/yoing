@testable import YoingCore
import XCTest

final class MultipartFormDataTests: XCTestCase {
    func testMultipartFieldsAndFileAreEncodedInOrder() throws {
        var form = MultipartFormData(boundary: "test-boundary")
        form.appendField(name: "format", value: "true")
        form.appendField(name: "language", value: "en")
        form.appendFile(
            name: "file",
            filename: "sample.m4a",
            mimeType: "audio/m4a",
            data: Data([0x01, 0x02, 0x03])
        )
        form.finalize()

        let body = try XCTUnwrap(String(data: form.body, encoding: .utf8))
        XCTAssertTrue(body.contains("Content-Disposition: form-data; name=\"format\""))
        XCTAssertTrue(body.contains("Content-Disposition: form-data; name=\"language\""))
        XCTAssertTrue(body.contains("Content-Disposition: form-data; name=\"file\"; filename=\"sample.m4a\""))
        XCTAssertTrue(body.hasSuffix("--test-boundary--\r\n"))

        let formatIndex = try XCTUnwrap(body.range(of: "name=\"format\"")?.lowerBound)
        let languageIndex = try XCTUnwrap(body.range(of: "name=\"language\"")?.lowerBound)
        let fileIndex = try XCTUnwrap(body.range(of: "name=\"file\"")?.lowerBound)

        XCTAssertLessThan(formatIndex, languageIndex)
        XCTAssertLessThan(languageIndex, fileIndex)
    }
}
