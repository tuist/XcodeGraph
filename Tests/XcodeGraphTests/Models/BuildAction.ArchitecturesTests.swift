import Foundation
import XCTest

@testable import XcodeGraph

final class BuildActionArchitecturesTests: XCTestCase {
    func test_codable() {
        // Given
        let subject = BuildAction.Architectures.universal

        // Then
        XCTAssertCodable(subject)
    }
}
