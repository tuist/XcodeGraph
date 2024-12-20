import Foundation
import Path
import XcodeGraph

import Foundation
import Path
import XcodeGraph

// MARK: - WorkspaceFixture

/// Provides references to sample Xcode workspace fixtures used for integration testing.
enum WorkspaceFixture: String, CaseIterable {
    case commandLineToolWithDynamicFramework = "command_line_tool_with_dynamic_framework/CommandLineTool"
    case iosAppWithRemoteSwiftPackage = "ios_app_with_remote_swift_package/App"
    case iosAppWithSpmDependencies = "ios_app_with_spm_dependencies/App"
    case iosAppWithExtensions = "ios_app_with_extensions/App"
    case iosAppWithMultiConfigs = "ios_app_with_multi_configs/Workspace"
    case iosWorkspaceWithMicrofeatureArchitectureStaticLinking =
        "ios_workspace_with_microfeature_architecture_static_linking/Workspace"
    case multiplatformAppWithMacrosAndEmbeddedWatchosApp =
        "multiplatform_app_with_macros_and_embedded_watchos_app/AppWithWatchApp"
    case iosAppLarge = "ios_app_large/App"
    case ios_app_with_transitive_framework = "ios_app_with_transitive_framework/Workspace"
    case macosAppWithSystemExtension = "macos_app_with_system_extension/App with SystemExtension"
    case iosAppWithStaticLibraries = "ios_app_with_static_libraries/iOSAppWithTransistiveStaticLibraries"
    case tuist = "tuist/Tuist"

    var fileExtension: String { "xcworkspace" }

    // NOTE: - This is temporary to reduce PR noise
    /// Unzips and returns path to the Fixtures directory, if not already done.
    static func getFixturesPath() throws -> String {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fixturesDir = tempDir.appendingPathComponent("Fixtures")

        // If already unzipped, return early.
        guard !fileManager.fileExists(atPath: fixturesDir.path) else {
            return fixturesDir.path
        }

        // Otherwise, unzip the fixtures.
        let zipPath = try AbsolutePath(validating: #filePath)
            .parentDirectory
            .parentDirectory
            .appending(components: "Resources", "Fixtures.zip")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = [zipPath.pathString, "-d", fixturesDir.path]
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw NSError(domain: "UnzipError", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: "Failed to unzip fixtures",
            ])
        }

        return fixturesDir.path
    }

    /// Returns the absolute path to this fixture's workspace.
    func absolutePath() throws -> AbsolutePath {
        let fixturesDir = try Self.getFixturesPath()
        return try AbsolutePath(validating: "\(fixturesDir)/\(rawValue).\(fileExtension)")
    }
}
