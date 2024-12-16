import Path
import XcodeProj

extension XCWorkspaceDataFileRef {
    /// Resolves the absolute path referenced by this `XCWorkspaceDataFileRef`.
    ///
    /// - Parameter srcPath: The workspace source root path.
    /// - Returns: The resolved `AbsolutePath` of this file reference.
    func absolutePath(srcPath: AbsolutePath) throws -> AbsolutePath {
        switch location {
        case let .absolute(path):
            return try AbsolutePath.resolvePath(path)
        case let .container(subPath):
            let relativePath = try RelativePath(validating: subPath)
            return srcPath.appending(relativePath)
        case let .developer(subPath):
            let relativePath = try RelativePath(validating: subPath)
            let developerPath = try AbsolutePath.resolvePath("/Applications/Xcode.app/Contents/Developer")
            return developerPath.appending(relativePath)
        case let .group(subPath):
            // Group paths are relative to the workspace file itself
            let relativePath = try RelativePath(validating: subPath)
            return srcPath.appending(relativePath)
        case let .current(subPath):
            // Current paths are relative to the current directory
            let relativePath = try RelativePath(validating: subPath)
            return srcPath.appending(relativePath)
        case let .other(type, subPath):
            // Other path types: prefix with the type and append subpath
            let relativePath = try RelativePath(validating: "\(type)/\(subPath)")
            return srcPath.appending(relativePath)
        }
    }
}
