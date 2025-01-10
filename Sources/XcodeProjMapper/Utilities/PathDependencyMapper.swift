import Foundation
import Path
import XcodeGraph

protocol PathDependencyMapping {
    func map(path: AbsolutePath, condition: PlatformCondition?) throws -> TargetDependency
}

struct PathDependencyMapper: PathDependencyMapping {
    /// Maps a path by its extension to a `TargetDependency` if applicable.
    ///
    /// - Parameter condition: Optional platform condition.
    /// - Returns: A `TargetDependency` if the extension matches known dependency types.
    func map(path: AbsolutePath, condition: PlatformCondition?) throws -> TargetDependency {
        let status: LinkingStatus = .required
        switch path.fileExtension {
        case .framework:
            return .framework(path: path, status: status, condition: condition)
        case .xcframework:
            return .xcframework(path: path, status: status, condition: condition)
        case .dynamicLibrary, .textBasedDynamicLibrary, .staticLibrary:
            return .library(
                path: path,
                publicHeaders: path.parentDirectory,
                swiftModuleMap: nil,
                condition: condition
            )
        case .xcodeproj, .xcworkspace, .coreData, .playground, .none:
            throw PathDependencyError.invalidExtension(path: path.pathString)
        }
    }
}

enum PathDependencyError: Error, LocalizedError {
    case invalidExtension(path: String)

    var errorDescription: String? {
        switch self {
        case let .invalidExtension(path):
            return "Encountered an invalid file extension for path. \(path)"
        }
    }
}

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
    var fileExtension: FileExtension? {
        guard let ext = self.extension?.lowercased() else { return nil }
        return FileExtension(rawValue: ext)
    }
}
