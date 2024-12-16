import Foundation
import Path
import PathKit
import XcodeGraph
@preconcurrency import XcodeProj

/// A protocol that defines how to provide access to an Xcode project and its underlying components.
///
/// Conforming types give you a parsed `XcodeProj` instance, the `.xcodeproj` file path, and the root source directory.
/// They also simplify retrieval of the main `PBXProject`, allowing downstream mappers or analyses to easily navigate
/// and process the project structure.
public protocol ProjectProviding: Sendable {
    /// The absolute path to the directory containing the Xcode project.
    ///
    /// Typically, this is the directory above the `.xcodeproj` file, serving as the project’s source root.
    var sourceDirectory: AbsolutePath { get }

    /// The absolute path to the `.xcodeproj` file.
    ///
    /// This path uniquely identifies the Xcode project file on disk.
    var xcodeProjPath: AbsolutePath { get }

    /// The parsed `XcodeProj` instance representing the Xcode project.
    ///
    /// `XcodeProj` provides structured access to projects, targets, build configurations, groups, and files,
    /// enabling advanced analysis or transformation tasks.
    var xcodeProj: XcodeProj { get }

    /// Returns the main `PBXProject` object from the `.xcodeproj`.
    ///
    /// The `PBXProject` object serves as the root for most project-related data, including build configurations, targets,
    /// and references to files and groups.
    ///
    /// - Throws: `MappingError.noProjectsFound` if no projects are found in the `.xcodeproj`.
    /// - Returns: A `PBXProject` representing the primary project definition.
    func pbxProject() throws -> PBXProject
}

extension ProjectProviding {
    /// A convenience property providing the source directory as a string.
    ///
    /// Useful for passing to APIs that require string paths instead of `AbsolutePath`.
    public var sourcePathString: String {
        sourceDirectory.pathString
    }

    /// The source directory is assumed to be the parent of the `.xcodeproj` directory.
    ///
    /// This default implementation infers the source directory from the `xcodeProjPath`, ensuring a consistent
    /// project structure.
    public var sourceDirectory: AbsolutePath {
        xcodeProjPath.parentDirectory
    }

    public func pbxProject() throws -> PBXProject {
        guard let pbxProject = xcodeProj.pbxproj.projects.first else {
            throw MappingError.noProjectsFound(path: xcodeProjPath.pathString)
        }
        return pbxProject
    }
}

/// A concrete provider that supplies information about a particular Xcode project.
///
/// `ProjectProvider` encapsulates a `.xcodeproj` file and its parsed `XcodeProj` representation, making it straightforward
/// to integrate with mappers or other tooling that requires consistent access to the project's structure.
///
/// **Example Usage:**
/// ```swift
/// import XcodeProj
///
/// // Assume you have an AbsolutePath to the .xcodeproj file.
/// let xcodeProjPath: AbsolutePath = ...
///
/// // Parse the project using XcodeProj.
/// let xcodeProj = try XcodeProj(pathString: xcodeProjPath.pathString)
///
/// // Create a ProjectProvider instance.
/// let projectProvider = ProjectProvider(xcodeProjPath: xcodeProjPath, xcodeProj: xcodeProj)
///
/// // Access the main PBXProject for further analysis:
/// let pbxProject = try projectProvider.pbxProject()
///
/// // From here, you can iterate targets, fetch build settings, or integrate with other mappers.
/// ```
public struct ProjectProvider: ProjectProviding {
    public let xcodeProj: XcodeProj
    public let xcodeProjPath: AbsolutePath

    /// Initializes a new `ProjectProvider` with the given project path and `XcodeProj` instance.
    ///
    /// - Parameters:
    ///   - xcodeProjPath: The absolute path to the `.xcodeproj` file.
    ///   - xcodeProj: The parsed `XcodeProj` instance representing the project.
    ///
    /// After initialization, `ProjectProvider` can serve as a bridge between `.xcodeproj` structures
    /// and higher-level mapping tools (e.g., `ProjectMapper`, `TargetMapper`), providing consistent and
    /// convenient access to all project data.
    public init(xcodeProjPath: AbsolutePath, xcodeProj: XcodeProj) {
        self.xcodeProjPath = xcodeProjPath
        self.xcodeProj = xcodeProj
    }
}
