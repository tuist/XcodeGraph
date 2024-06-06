import Foundation
import XCTest
import Path

@testable import XcodeGraph

final class ExecutionActionTests: XCTestCase {
    func test_codable() {
        // Given
        let subject = ExecutionAction(
            title: "title",
            scriptText: "text",
            target: .init(
                projectPath: try! AbsolutePath(validating: "/path/to/project"),
                name: "name"
            ),
            shellPath: nil,
            showEnvVarsInLog: false
        )

        // Then
        XCTAssertCodable(subject)
    }
}
