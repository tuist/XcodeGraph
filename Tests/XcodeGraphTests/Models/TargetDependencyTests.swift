import Foundation
import Path
import XCTest

@testable import XcodeGraph

final class TargetDependencyTests: XCTestCase {
    func test_codable_framework() {
        // Given
        let subject = TargetDependency.framework(
            path: try! AbsolutePath(validating: "/path/to/framework"),
            status: .required
        )

        // Then
        XCTAssertCodable(subject)
    }

    func test_codable_project() {
        // Given
        let subject = TargetDependency.project(target: "target", path: try! AbsolutePath(validating: "/path/to/target"))

        // Then
        XCTAssertCodable(subject)
    }

    func test_codable_library() {
        // Given
        let subject = TargetDependency.library(
            path: try! AbsolutePath(validating: "/path/to/library"),
            publicHeaders: try! AbsolutePath(validating: "/path/to/publicheaders"),
            swiftModuleMap: try! AbsolutePath(validating: "/path/to/swiftModuleMap")
        )

        // Then
        XCTAssertCodable(subject)
    }

    func test_codable_foreignBuild() {
        // Given
        let subject = TargetDependency.foreignBuild(
            name: "SharedKMP",
            script: "./gradlew build",
            inputs: [
                .file(try! AbsolutePath(validating: "/path/to/input.kt")),
                .folder(try! AbsolutePath(validating: "/path/to/src")),
                .glob("**/*.kt"),
                .script("git rev-parse HEAD"),
            ],
            output: .xcframework(
                path: try! AbsolutePath(validating: "/path/to/output.xcframework"),
                linking: .dynamic
            )
        )

        // Then
        XCTAssertCodable(subject)
    }

    func test_filtering() {
        let expected: PlatformCondition? = .when([.macos])

        let subjects: [TargetDependency] = [
            .framework(path: try! AbsolutePath(validating: "/"), status: .required, condition: expected),
            .library(
                path: try! AbsolutePath(validating: "/"),
                publicHeaders: try! AbsolutePath(validating: "/"),
                swiftModuleMap: try! AbsolutePath(validating: "/"),
                condition: expected
            ),
            .sdk(name: "", status: .required, condition: expected),
            .package(product: "", type: .plugin, condition: expected),
            .target(name: "", condition: expected),
            .xcframework(
                path: try! AbsolutePath(validating: "/"),
                expectedSignature: nil,
                status: .required,
                condition: expected
            ),
            .project(target: "", path: try! AbsolutePath(validating: "/"), condition: expected),
            .foreignBuild(
                name: "KMP",
                script: "./build.sh",
                inputs: [.file(try! AbsolutePath(validating: "/input.kt"))],
                output: .xcframework(
                    path: try! AbsolutePath(validating: "/output.xcframework"),
                    linking: .dynamic
                ),
                condition: expected
            ),
        ]

        for subject in subjects {
            XCTAssertEqual(subject.condition, expected)
            XCTAssertEqual(subject.withCondition(.when([.catalyst])).condition, .when([.catalyst]))
        }
    }

    func test_xctest_platformFilters_alwaysReturnAll() {
        let subject = TargetDependency.xctest

        XCTAssertNil(subject.condition)
        XCTAssertNil(subject.withCondition(.when([.catalyst])).condition)
    }
}
