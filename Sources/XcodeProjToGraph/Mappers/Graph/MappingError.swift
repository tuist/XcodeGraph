import Foundation
import Path

/// Represents errors that may occur during project or dependency mapping processes.
public enum MappingError: Error, LocalizedError, Equatable {
    // MARK: - Project Mapping Errors

    /// The provided path does not exist.
    case pathNotFound(path: String)

    /// The provided project type is unknown.
    case unknownProjectType(path: String)

    /// No projects were found in the Xcode project file.
    case noProjectsFound(path: String)

    /// The main files group is missing for a target.
    case missingFilesGroup(targetName: String)

    /// The merged binary type for a target is missing.
    case missingMergedBinaryType

    /// The repository URL is missing from the package reference.
    case missingRepositoryURL(packageName: String)

    /// A generic mapping error with a message.
    case generic(String)

    // MARK: - Target Mapping Errors

    /// The bundle identifier is missing from the build settings of a target.
    case missingBundleIdentifier(targetName: String)

    /// The specified target could not be found.
    case targetNotFound(targetName: String, path: AbsolutePath)

    // MARK: - Dependency Mapping Errors

    /// A required framework dependency was not found.
    case frameworkNotFound(name: String, path: AbsolutePath)

    /// An unknown dependency type was encountered.
    case unknownDependencyType(name: String)

    // MARK: - Error Descriptions

    public var errorDescription: String? {
        switch self {
        case let .pathNotFound(path):
            return "The specified path does not exist: \(path)"
        case let .unknownProjectType(path):
            return "The project type for the path '\(path)' could not be determined."
        case let .noProjectsFound(path):
            return "No Xcode projects were found at: \(path)"
        case let .missingFilesGroup(targetName):
            return "The files group is missing for the target '\(targetName)'."
        case .missingMergedBinaryType:
            return "The merged binary type is missing for the target."
        case let .missingRepositoryURL(packageName):
            return "The repository URL is missing for the package '\(packageName)'."
        case let .generic(message):
            return message
        case let .missingBundleIdentifier(targetName):
            return "The bundle identifier is missing for the target '\(targetName)'."
        case let .targetNotFound(targetName, path):
            return "The target '\(targetName)' could not be found in the project at path: \(path.pathString)."
        case let .frameworkNotFound(name, path):
            return "The required framework '\(name)' was not found at path: \(path.pathString)."
        case let .unknownDependencyType(name):
            return "An unknown dependency type '\(name)' was encountered."
        }
    }
}
