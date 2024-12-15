import Path
import XcodeProj

extension XCWorkspaceDataFileRef {
    func absolutePath(srcPath: AbsolutePath) throws -> AbsolutePath {
        switch location {
        case let .absolute(path):
            let absolutePath = try AbsolutePath.resolvePath(path)
            return absolutePath
        case let .container(subPath):
            let relativePath = try RelativePath(validating: subPath)
            let absolutePath = srcPath.appending(relativePath)
            return absolutePath
        case let .developer(subPath):
            let relativePath = try RelativePath(validating: subPath)
            let developerPath = try AbsolutePath.resolvePath("/Applications/Xcode.app/Contents/Developer")
            let absolutePath = developerPath.appending(relativePath)
            return absolutePath
        case let .group(subPath):
            // Group paths are relative to the workspace file itself
            let relativePath = try RelativePath(validating: subPath)
            let absolutePath = srcPath.appending(relativePath)
            return absolutePath
        case let .current(subPath):
            // Current paths are relative to the current directory (commonly workspace path)
            let relativePath = try RelativePath(validating: subPath)
            let absolutePath = srcPath.appending(relativePath)
            return absolutePath
        case let .other(type, subPath):
            // Handle other path types by prefixing with the type and appending the subpath
            let relativePath = try RelativePath(validating: "\(type)/\(subPath)")
            let absolutePath = srcPath.appending(relativePath)
            return absolutePath
        }
    }
}
