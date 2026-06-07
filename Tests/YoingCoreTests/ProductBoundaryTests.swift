import Foundation
import XCTest

final class ProductBoundaryTests: XCTestCase {
    func testSourceDoesNotUsePasteboardAPIs() throws {
        let packageRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let sourceRoot = packageRoot.appendingPathComponent("Sources")
        let files = try swiftFiles(in: sourceRoot)

        let forbiddenTerms = [
            "NSPasteboard",
            "UIPasteboard",
            "Pasteboard.general"
        ]

        for file in files {
            let contents = try String(contentsOf: file, encoding: .utf8)

            for term in forbiddenTerms {
                XCTAssertFalse(
                    contents.contains(term),
                    "\(file.path) contains forbidden API term \(term)"
                )
            }
        }
    }

    private func swiftFiles(in root: URL) throws -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return try enumerator.compactMap { item in
            guard let url = item as? URL, url.pathExtension == "swift" else {
                return nil
            }

            let values = try url.resourceValues(forKeys: [.isRegularFileKey])
            return values.isRegularFile == true ? url : nil
        }
    }
}
