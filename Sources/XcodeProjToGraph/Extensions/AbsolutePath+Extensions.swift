import Foundation
import Path
import XcodeGraph

/// Common file extensions encountered in Xcode projects and their associated artifacts.
enum FileExtension: String {
    case xcodeproj
    case xcworkspace
    case framework
    case xcframework
    case staticLibrary = "a"
    case dynamicLibrary = "dylib"
    case textBasedDynamicLibrary = "tbd"
    case coreData = "xcdatamodeld"
    case playground
}

extension AbsolutePath {
    /// Attempts to resolve an array of path strings into `AbsolutePath` instances.
    ///
    /// - Parameter paths: The string paths to resolve.
    /// - Returns: An array of `AbsolutePath` if resolution succeeds.
    public static func resolvePaths(
        _ paths: [String]?
    ) throws -> [AbsolutePath] {
        return try paths?.compactMap { try AbsolutePath.resolvePath($0) } ?? []
    }

    /// Attempts to resolve an optional path string into an `AbsolutePath`.
    ///
    /// - Parameter path: The path string to resolve.
    /// - Returns: An `AbsolutePath` or `nil` if the path is `nil`.
    public static func resolveOptionalPath(
        _ path: String?
    ) throws -> AbsolutePath? {
        guard let path else { return nil }
        return try AbsolutePath.resolvePath(path)
    }

    /// Resolves a path string into an `AbsolutePath`, optionally relative to another path.
    ///
    /// Throws an error if the path is invalid.
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
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }
    }

    /// Maps a path by its extension to a `TargetDependency` if applicable.
    ///
    /// - Parameter condition: Optional platform condition.
    /// - Returns: A `TargetDependency` if the extension matches known dependency types.
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
