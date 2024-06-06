import Foundation
import Path
import XCTest

@testable import XcodeGraph

final class ProfileActionTests: XCTestCase {
    func test_codable() {
        // Given
        let subject = ProfileAction(
            configurationName: "name",
            executable: .init(
                projectPath: try! AbsolutePath(validating: "/path/to/project"),
                name: "name"
            ),
            arguments: .init(
                environmentVariables: [
                    "key": EnvironmentVariable(value: "value", isEnabled: true),
                ],
                launchArguments: [
                    .init(
                        name: "name",
                        isEnabled: false
                    ),
                ]
            )
        )

        // Then
        XCTAssertCodable(subject)
    }
}
