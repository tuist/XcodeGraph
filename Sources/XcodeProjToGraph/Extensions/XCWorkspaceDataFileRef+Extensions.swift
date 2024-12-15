import Path
import XcodeProj

extension XCWorkspaceDataFileRef {
  func absolutePath(srcPath: AbsolutePath) throws -> AbsolutePath {
    switch location {
    case .absolute(let path):
      let absolutePath = try AbsolutePath.resolvePath(path)
      return absolutePath
    case .container(let subPath):
      let relativePath = try RelativePath(validating: subPath)
      let absolutePath = srcPath.appending(relativePath)
      return absolutePath
    case .developer(let subPath):
      let relativePath = try RelativePath(validating: subPath)
      let developerPath = try AbsolutePath.resolvePath("/Applications/Xcode.app/Contents/Developer")
      let absolutePath = developerPath.appending(relativePath)
      return absolutePath
    case .group(let subPath):
      // Group paths are relative to the workspace file itself
      let relativePath = try RelativePath(validating: subPath)
      let absolutePath = srcPath.appending(relativePath)
      return absolutePath
    case .current(let subPath):
      // Current paths are relative to the current directory (commonly workspace path)
      let relativePath = try RelativePath(validating: subPath)
      let absolutePath = srcPath.appending(relativePath)
      return absolutePath
    case .other(let type, let subPath):
      // Handle other path types by prefixing with the type and appending the subpath
      let relativePath = try RelativePath(validating: "\(type)/\(subPath)")
      let absolutePath = srcPath.appending(relativePath)
      return absolutePath
    }
  }
}
