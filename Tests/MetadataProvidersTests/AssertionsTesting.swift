import Foundation
import Path
import ServiceContextModule
import Testing

struct AssertionsTesting {
    // MARK: - Fixtures

    /// Resolves a fixture path relative to the project's root.
    static func fixturePath(path: RelativePath) -> AbsolutePath {
        try! AbsolutePath(
            validating: ProcessInfo.processInfo.environment["TUIST_CONFIG_SRCROOT"]!
        )
        .appending(components: "Tests", "Fixtures")
        .appending(path)
    }
}


extension AbsolutePath: Swift.ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        do {
            self = try AbsolutePath(validating: value)
        } catch {
            Issue.record("Invalid path at: \(value) - Error: \(error)")
            self = AbsolutePath("/")
        }
    }
}
