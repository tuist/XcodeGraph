import Foundation
import XCTest
import Path

@testable import XcodeGraph

final class SourceFileTests: XCTestCase {
    func test_codable() {
        // Given
        let subject = SourceFile(
            path: try! AbsolutePath(validating: "/path/to/file"),
            compilerFlags: "flag",
            contentHash: "hash"
        )

        // Then
        XCTAssertCodable(subject)
    }
}
