import Foundation
import Path
import PathKit
import XcodeGraph
import XcodeProj

/// Errors that may occur while providing project information.
enum ProjectProvidingError: LocalizedError, Equatable {
    case noProjectsFound(path: String)

    var errorDescription: String? {
        switch self {
        case let .noProjectsFound(path):
            return "No `PBXProject` was found in the `.xcodeproj` at: \(path)."
        }
    }
}

/// A protocol that defines how to provide access to an Xcode project and its underlying components.
///
/// Conforming types must supply:
/// - A parsed `XcodeProj` instance
/// - The `.xcodeproj` file path
/// - The project’s source directory
/// - A method to retrieve the main `PBXProject`
protocol ProjectProviding {
    /// The absolute path to the directory containing the Xcode project.
    var sourceDirectory: AbsolutePath { get }

    /// The absolute path to the `.xcodeproj` file.
    var xcodeProjPath: AbsolutePath { get }

    /// The parsed `XcodeProj` instance representing the Xcode project.
    var xcodeProj: XcodeProj { get }

    /// Returns the main `PBXProject` object from the `.xcodeproj`.
    ///
    /// - Throws: `ProjectProvidingError.noProjectsFound` if no projects are found.
    /// - Returns: A `PBXProject` representing the primary project definition.
    func pbxProject() throws -> PBXProject
}

extension ProjectProviding {
    var sourcePathString: String {
        sourceDirectory.pathString
    }
}

/// A concrete provider supplying information about a particular Xcode project.
///
/// `ProjectProvider` holds a `.xcodeproj` file path and its `XcodeProj` representation, enabling integration
/// with mappers or tooling that require direct access to the project's structure.
struct ProjectProvider: ProjectProviding {
    let xcodeProj: XcodeProj
    let xcodeProjPath: AbsolutePath

    /// Initializes a new `ProjectProvider` with the given `.xcodeproj` path and `XcodeProj` instance.
    ///
    /// - Parameters:
    ///   - xcodeProjPath: The absolute path to the `.xcodeproj` file.
    ///   - xcodeProj: The parsed `XcodeProj` instance.
    init(xcodeProjPath: AbsolutePath, xcodeProj: XcodeProj) {
        self.xcodeProjPath = xcodeProjPath
        self.xcodeProj = xcodeProj
    }

    /// The source directory is assumed to be the parent of the `.xcodeproj` directory.
    ///
    /// This implementation infers the source directory from the `xcodeProjPath`, ensuring a consistent
    /// project structure.
    var sourceDirectory: AbsolutePath {
        xcodeProjPath.parentDirectory
    }

    func pbxProject() throws -> PBXProject {
        guard let pbxProject = xcodeProj.pbxproj.projects.first else {
            throw ProjectProvidingError.noProjectsFound(path: xcodeProjPath.pathString)
        }
        return pbxProject
    }
}
