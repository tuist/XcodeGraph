import Foundation
import Path
import XCTest

@testable import XcodeGraph

final class TestableTargetTests: XCTestCase {
    func test_codable() {
        // Given
        let subject = TestableTarget(
            target: .init(
                projectPath: try! AbsolutePath(validating: "/path/to/project"),
                name: "name"
            ),
            skipped: true,
            parallelizable: true,
            randomExecutionOrdering: true
        )

        // Then
        XCTAssertCodable(subject)
    }
}
