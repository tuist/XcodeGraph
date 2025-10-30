import Foundation
import Path
import XCTest

@testable import XcodeGraph

final class PackageTests: XCTestCase {
    func test_codable_local() {
        // Given
        let subject = Package.local(path: try! AbsolutePath(validating: "/path/to/workspace"), groupPath: nil)

        // Then
        XCTAssertCodable(subject)
    }

    func test_codable_remote() {
        // Given
        let subject = Package.remote(
            url: "/url/to/package",
            requirement: .branch("branch")
        )

        // Then
        XCTAssertCodable(subject)
    }

    func test_is_remote_local() {
        // Given
        let subject = Package.local(path: try! AbsolutePath(validating: "/path/to/package"), groupPath: nil)

        // Then
        XCTAssertFalse(subject.isRemote)
    }

    func test_is_remote_remote() {
        // Given
        let subject = Package.remote(
            url: "/url/to/package",
            requirement: .branch("branch")
        )

        // Then
        XCTAssertTrue(subject.isRemote)
    }
}
