import Foundation
import XCTest
import Path

@testable import XcodeGraph

final class TestPlanTests: XCTestCase {
    func test_codable() {
        // Given
        let subject = TestPlan(
            path: try! AbsolutePath(validating: "/path/to"),
            testTargets: [],
            isDefault: true
        )

        // Then
        XCTAssertCodable(subject)
    }
}
