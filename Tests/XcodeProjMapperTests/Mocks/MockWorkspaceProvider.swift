import Path
import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeProjMapper

/// A mock workspace provider for testing, supplying an XCWorkspace and directory paths.
struct MockWorkspaceProvider: WorkspaceProviding {
    var workspaceDirectory: AbsolutePath
    var xcWorkspacePath: AbsolutePath
    var xcworkspace: XCWorkspace

    init(xcWorkspacePath: AbsolutePath, xcworkspace: XCWorkspace) {
        self.xcWorkspacePath = xcWorkspacePath
        workspaceDirectory = xcWorkspacePath.parentDirectory
        self.xcworkspace = xcworkspace
    }
}
