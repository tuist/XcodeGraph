import Foundation
import Path
import PathKit
import XcodeGraph
@preconcurrency import XcodeProj

/// A protocol defining how to provide access to an Xcode project and its underlying components.
///
/// Conforming types must specify the project's source directory, the `.xcodeproj` path,
/// and a parsed `XcodeProj` instance. They also provide a convenient way to retrieve
/// the main `PBXProject` object from the project.
public protocol ProjectProviding: Sendable {
  /// The absolute path to the directory containing the Xcode project.
  var sourceDirectory: AbsolutePath { get }

  /// The absolute path to the `.xcodeproj` file.
  var xcodeProjPath: AbsolutePath { get }

  /// The parsed `XcodeProj` instance representing the Xcode project.
  var xcodeProj: XcodeProj { get }

  /// Returns the main `PBXProject` object from the `.xcodeproj`.
  ///
  /// - Throws: `MappingError.noProjectsFound` if no projects are found in the `.xcodeproj`.
  /// - Returns: A `PBXProject` representing the primary project definition.
  func pbxProject() throws -> PBXProject
}

extension ProjectProviding {
  /// A convenience property providing the source directory as a string.
  public var sourcePathString: String {
    sourceDirectory.pathString
  }

  /// The source directory is assumed to be the parent of the `.xcodeproj` directory.
  public var sourceDirectory: AbsolutePath {
    xcodeProjPath.parentDirectory
  }

  public func pbxProject() throws -> PBXProject {
    guard let pbxProject = xcodeProj.pbxproj.projects.first else {
      // TODO: - Add path assocaited value
      throw MappingError.noProjectsFound
    }
    return pbxProject
  }
}

/// A concrete provider that supplies information about a particular Xcode project.
///
/// `ProjectProvider` wraps a given `.xcodeproj` file, providing access to its
/// `XcodeProj` representation and the associated file paths. It simplifies operations
/// that need to read or analyze the project structure.
public struct ProjectProvider: ProjectProviding {
  public let xcodeProj: XcodeProj
  public let xcodeProjPath: AbsolutePath

  /// Initializes a new `ProjectProvider` with the given project path and `XcodeProj` instance.
  ///
  /// - Parameters:
  ///   - xcodeProjPath: The absolute path to the `.xcodeproj` file.
  ///   - xcodeProj: The parsed `XcodeProj` instance representing the project.
  public init(xcodeProjPath: AbsolutePath, xcodeProj: XcodeProj) {
    self.xcodeProjPath = xcodeProjPath
    self.xcodeProj = xcodeProj
  }
}
