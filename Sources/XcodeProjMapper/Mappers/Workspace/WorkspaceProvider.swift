import Foundation
import Path
import PathKit
import XcodeGraph
import XcodeProj

/// A protocol that defines how to provide access to a `.xcworkspace` file and its parsed representation.
///
/// Conforming types supply:
/// - The directory containing the workspace (`workspaceDirectory`).
/// - The absolute path to the `.xcworkspace` file (`xcWorkspacePath`).
/// - A parsed `XCWorkspace` instance, enabling exploration of the workspace structure.
///
/// By abstracting these details, tooling can easily navigate and analyze workspaces, discovering contained projects
/// and shared schemes without having to manually resolve file paths or parse the workspace file.
protocol WorkspaceProviding {
    /// The absolute path to the directory containing the `.xcworkspace` file.
    var workspaceDirectory: AbsolutePath { get }

    /// The absolute path to the `.xcworkspace` file.
    var xcWorkspacePath: AbsolutePath { get }

    /// The parsed `XCWorkspace` instance representing the workspace.
    var xcworkspace: XCWorkspace { get }
}

/// A concrete provider for workspaces, offering easy access to the `.xcworkspace` file and its parsed representation.
///
/// `WorkspaceProvider` streamlines the process of working with Xcode workspaces by:
/// - Determining and storing the `xcWorkspacePath`.
/// - Providing the `workspaceDirectory` as the parent directory of the `.xcworkspace` file.
/// - Loading and storing the parsed `XCWorkspace` instance.
///
/// **Example Usage:**
/// ```swift
/// import XcodeProj
///
/// // Assume you have an AbsolutePath to the .xcworkspace file.
/// let workspacePath: AbsolutePath = ...
///
/// // Create a WorkspaceProvider instance
/// let workspaceProvider = try WorkspaceProvider(xcWorkspacePath: workspacePath)
///
/// // Access the parsed XCWorkspace
/// let xcworkspace = workspaceProvider.xcworkspace
///
/// // From here, you can inspect workspace elements, discover contained projects, or integrate with other mappers.
/// ```
struct WorkspaceProvider: WorkspaceProviding {
    let workspaceDirectory: AbsolutePath
    let xcWorkspacePath: AbsolutePath
    let xcworkspace: XCWorkspace

    /// Initializes a `WorkspaceProvider` with a given workspace path.
    ///
    /// - Parameter xcWorkspacePath: The absolute path to the `.xcworkspace` file.
    /// - Throws: If the `.xcworkspace` file cannot be loaded or parsed.
    ///
    /// Once initialized, `WorkspaceProvider` can be passed to tools like `WorkspaceMapper` to produce a `Workspace` model,
    /// or used directly to gather workspace-related data.
    init(xcWorkspacePath: AbsolutePath) throws {
        self.xcWorkspacePath = xcWorkspacePath
        workspaceDirectory = xcWorkspacePath.parentDirectory
        xcworkspace = try XCWorkspace(path: Path(xcWorkspacePath.pathString))
    }
}
