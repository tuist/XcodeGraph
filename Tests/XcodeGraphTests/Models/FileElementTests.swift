import Foundation
import Path
import XCTest

@testable import XcodeGraph

final class FileElementTests: XCTestCase {
    func test_codable_file() {
        // Given
        let subject = FileElement.file(path: try! AbsolutePath(validating: "/path/to/file"))

        // Then
        XCTAssertCodable(subject)
    }

    func test_codable_folderReference() {
        // Given
        let subject = FileElement.folderReference(path: try! AbsolutePath(validating: "/folder/reference"))

        // Then
        XCTAssertCodable(subject)
    }
}
