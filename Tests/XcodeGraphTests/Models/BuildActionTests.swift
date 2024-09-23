import Foundation
import Path
import XCTest

@testable import XcodeGraph

final class BuildActionTests: XCTestCase {
    func test_codable() {
        // Given
        let subject = BuildAction(
            targetsWithBuildFor: [
                BuildAction.Target(TargetReference(
                    projectPath: try! AbsolutePath(validating: "/path/to/project"),
                    name: "name"
                ), buildFor: [.running]),
            ],
            preActions: [
                .init(
                    title: "preActionTitle",
                    scriptText: "text",
                    target: nil,
                    shellPath: nil,
                    showEnvVarsInLog: true
                ),
            ],
            postActions: [
                .init(
                    title: "postActionTitle",
                    scriptText: "text",
                    target: nil,
                    shellPath: nil,
                    showEnvVarsInLog: false
                ),
            ]
        )

        // Then
        XCTAssertCodable(subject)
    }
}
