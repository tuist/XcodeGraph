import Foundation
import XCTest
import Path

@testable import XcodeGraph

final class GraphTests: XCTestCase {
    func test_codable() {
        // Given
        let subject = Graph.test(name: "name", path: try! AbsolutePath(validating: "/path/to"))

        // Then
        XCTAssertCodable(subject)
    }
}
