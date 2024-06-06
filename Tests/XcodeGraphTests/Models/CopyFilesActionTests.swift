import Foundation
import XCTest
import Path

@testable import XcodeGraph

final class CopyFilesActionTests: XCTestCase {
    func test_codable() {
        // Given
        let subject = CopyFilesAction(
            name: "name",
            destination: .frameworks,
            subpath: "subpath",
            files: [
                .file(path: try! AbsolutePath(validating: "/path/to/file")),
            ]
        )

        // Then
        XCTAssertCodable(subject)
    }
}
