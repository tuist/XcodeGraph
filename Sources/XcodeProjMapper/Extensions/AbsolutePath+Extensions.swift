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
    /// Maps a path by its extension to a `TargetDependency` if applicable.
    ///
    /// - Parameter condition: Optional platform condition.
    /// - Returns: A `TargetDependency` if the extension matches known dependency types.
    func mapByExtension(condition: PlatformCondition?) -> TargetDependency? {
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
