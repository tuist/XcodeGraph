import Foundation
import XCTest
import Path

@testable import XcodeGraph

final class TargetReferenceTests: XCTestCase {
    func test_codable() {
        // Given
        let subject = TargetReference(
            projectPath: try! AbsolutePath(validating: "/path/to/project"),
            name: "name"
        )

        // Then
        XCTAssertCodable(subject)
    }
}
