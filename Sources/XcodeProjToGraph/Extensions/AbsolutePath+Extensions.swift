import Foundation
import Path
import XcodeGraph

enum FileExtension: String {
  case xcodeproj
  case xcworkspace
  case framework
  case xcframework
  case staticLibrary = "a"
  case dynamicLibrary = "dylib"
  case textBasedDynamicLibrary = "tbd"
  case coreData = "xcdatamodeld"
  case playground = "playground"
}

extension AbsolutePath {
  public static func resolvePaths(
    _ paths: [String]?,
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) throws -> [AbsolutePath] {
    return try paths?.compactMap { try AbsolutePath.resolvePath($0) } ?? []
  }

  public static func resolveOptionalPath(
    _ path: String?,
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) throws -> AbsolutePath? {
    guard let path = path else { return nil }
    return try AbsolutePath.resolvePath(path)
  }

  public static func resolvePath(
    _ path: String,
    relativeTo: AbsolutePath? = nil,
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) throws -> AbsolutePath {
    do {
      if let relativeTo {
        return try AbsolutePath(validating: path, relativeTo: relativeTo)
      }
      return try AbsolutePath(validating: path)
    } catch {
      let message = """
        Invalid absolute path: '\(path)'
        Thrown in \(function) at \(file):\(line)
        Original error: \(error)
        """
      throw NSError(
        domain: "GraphMapperError", code: 1,
        userInfo: [
          NSLocalizedDescriptionKey: message
        ])
    }
  }


  public func mapByExtension(condition: PlatformCondition?) -> TargetDependency? {
    let status: LinkingStatus = .required
    let absPath = self
    switch absPath.fileExtension {
    case .framework:
      return .framework(path: absPath, status: status, condition: condition)
    case .xcframework:
      return .xcframework(path: absPath, status: status, condition: condition)
    case .dynamicLibrary, .textBasedDynamicLibrary, .staticLibrary:
      return .library(
        path: absPath,
        publicHeaders: absPath.parentDirectory,
        swiftModuleMap: nil,
        condition: condition
      )
    default:
      return nil
    }
  }

  var fileExtension: FileExtension? {
    guard let ext = self.extension?.lowercased() else { return nil }
    return FileExtension(rawValue: ext)
  }
}
