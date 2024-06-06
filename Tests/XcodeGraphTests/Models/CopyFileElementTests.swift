import Foundation
import XCTest
import Path

@testable import XcodeGraph

final class CopyFileElementTests: XCTestCase {
    func test_codable_file() {
        // Given
        let subject = CopyFileElement.file(path: try! AbsolutePath(validating: "/path/to/file"), condition: .when([.macos]))

        // Then
        XCTAssertCodable(subject)
    }

    func test_codable_folderReference() {
        // Given
        let subject = CopyFileElement.folderReference(path: try! AbsolutePath(validating: "/folder/reference"), condition: .when([.macos]))

        // Then
        XCTAssertCodable(subject)
    }
}
