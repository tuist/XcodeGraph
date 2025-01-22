import Foundation
import Path
import XcodeProj

extension XCWorkspace {
    /// A computed property that either returns the workspace’s `path`
    /// or throws a `MissingWorkspacePathError` if it’s `nil`.
    public var workspacePath: AbsolutePath {
        try! AbsolutePath(validating: path!.string)
    }
}

extension XcodeProj {
    /// A computed property that either returns the project’s `path`
    /// or throws a `MissingProjectPathError` if it’s `nil`.
    public var projectPath: AbsolutePath {
        try! AbsolutePath(validating: path!.string)
    }

    public var srcPath: AbsolutePath {
        projectPath.parentDirectory
    }

    public var srcPathString: String {
        srcPath.pathString
    }
}
