import Foundation
import Path
import PathKit
import XcodeGraph
import XcodeProj

/// A type that provides access to a workspace and its underlying `.xcworkspace` file.
public protocol WorkspaceProviding: Sendable {
  /// The absolute path to the workspace file.
  var workspaceDirectory: AbsolutePath { get }
    var xcWorkspacePath: AbsolutePath { get }

  /// The parsed `XCWorkspace` instance representing the workspace.
  var xcworkspace: XCWorkspace { get }
}

/// A concrete provider for workspaces, offering access to the `.xcworkspace` file and its parsed representation.
public struct WorkspaceProvider: WorkspaceProviding {
  public let workspaceDirectory: AbsolutePath
public let xcWorkspacePath: AbsolutePath
  public let xcworkspace: XCWorkspace

  /// Initializes a `WorkspaceProvider` with a given workspace path.
  ///
  /// - Parameter workspacePath: The absolute path to the `.xcworkspace` file.
  /// - Throws: If the `.xcworkspace` file cannot be loaded or parsed.
  public init(xcWorkspacePath: AbsolutePath) throws {
      self.xcWorkspacePath = xcWorkspacePath
      self.workspaceDirectory = xcWorkspacePath.parentDirectory
      self.xcworkspace = try XCWorkspace(path: Path(xcWorkspacePath.pathString))
  }
}
