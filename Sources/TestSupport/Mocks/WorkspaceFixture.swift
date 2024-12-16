import Foundation
import Path
import XcodeGraph

// MARK: - Workspace Fixtures

/// Provides references to sample Xcode workspace fixtures for testing.
public enum WorkspaceFixture: String, CaseIterable {
    case commandLineToolWithDynamicFramework =
        "command_line_tool_with_dynamic_framework/CommandLineTool"
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
    case iosAppWithStaticLibraries =
        "ios_app_with_static_libraries/iOSAppWithTransistiveStaticLibraries"

    public var fileExtension: String { "xcworkspace" }

    /// Returns the absolute path to the fixture workspace. Adjust the base path as needed.
    public func absolutePath() throws -> AbsolutePath {
        print(#filePath)

        let relativePath = try RelativePath(validating: "Fixtures/\(rawValue).\(fileExtension)")
        let p = try AbsolutePath.resolvePath(#filePath)
            .parentDirectory
            .parentDirectory
            .appending(relativePath)

        print(p)

        return p
    }
}
