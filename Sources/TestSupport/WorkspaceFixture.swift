import Foundation
import Path
import XcodeGraph

// MARK: - Workspace Fixtures

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

    public func absolutePath() throws -> AbsolutePath {
        return try AbsolutePath.resolvePath(
            "/Users/andykolean/Developer/XcodeGraphMapper/Tests/TestSupport/Fixtures/\(rawValue).xcworkspace"
        )
    }
}
