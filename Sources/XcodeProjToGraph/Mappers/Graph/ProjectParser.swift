import Foundation
import Path
import XcodeGraph
import XcodeProj

/// Specifies the type of project to parse.
/// - `.workspace(path)`: Indicates a `.xcworkspace` is present at the given path.
/// - `.xcodeProject(path)`: Indicates a `.xcodeproj` is present at the given path.
public enum ProjectType {
    case workspace(AbsolutePath)
    case xcodeProject(AbsolutePath)
}

/// A parser responsible for identifying and parsing Xcode projects or workspaces into a `Graph`.
///
/// `ProjectParser` determines whether the given path points to a workspace, a project,
/// or a directory containing one of these. It then delegates the actual mapping to `GraphMapper`.
public class ProjectParser {
    public init() {}

    /// Parses the project or workspace at the given file system path into a `Graph`.
    ///
    /// - Parameter path: The path to a `.xcworkspace`, `.xcodeproj`, or a directory containing one.
    /// - Returns: A `Graph` representing the parsed project structure.
    /// - Throws:
    ///   - `MappingError.pathNotFound` if the given path does not exist.
    ///   - `MappingError.noProjectsFound` if no `.xcworkspace` or `.xcodeproj` can be found.
    ///   - Other errors thrown by `GraphMapper` during mapping.
    public static func parse(atPath path: String) async throws -> Graph {
        guard FileManager.default.fileExists(atPath: path) else {
            throw MappingError.pathNotFound(path: path)
        }

        let absolutePath = try AbsolutePath(validating: path)
        let type = try determineProjectType(at: absolutePath)
        return try await parse(projectType: type)
    }

    /// Parses a given `ProjectType` into a `Graph`.
    ///
    /// - Parameter projectType: The identified `ProjectType` (workspace or project).
    /// - Returns: A `Graph` model.
    /// - Throws: Any errors encountered during graph mapping.
    public static func parse(projectType: ProjectType) async throws -> Graph {
        switch projectType {
        case let .workspace(path):
            return try await mapXCWorkspace(at: path)
        case let .xcodeProject(path):
            return try await mapXcodeProj(at: path)
        }
    }

    /// Maps a single `.xcodeproj` at the given path into a `Graph`.
    ///
    /// - Parameter path: The absolute path to the `.xcodeproj`.
    /// - Returns: A `Graph` model of the project.
    /// - Throws: Errors from `GraphMapper` if mapping fails.
    public static func mapXcodeProj(at path: AbsolutePath) async throws -> Graph {
        let graphMapper = GraphMapper(graphType: .project(path))
        return try await graphMapper.xcodeGraph()
    }

    /// Maps a single `.xcworkspace` at the given path into a `Graph`.
    ///
    /// - Parameter path: The absolute path to the `.xcworkspace`.
    /// - Returns: A `Graph` model of the workspace and its contained projects.
    /// - Throws: Errors from `GraphMapper` if mapping fails.
    public static func mapXCWorkspace(at path: AbsolutePath) async throws -> Graph {
        let workspaceProvider = try WorkspaceProvider(xcWorkspacePath: path)
        let graphMapper = GraphMapper(graphType: .workspace(workspaceProvider))
        return try await graphMapper.xcodeGraph()
    }

    /// Determines the type of project at a given path by inspecting file extensions or directory contents.
    ///
    /// - Parameter path: The absolute path to check.
    /// - Returns: A `ProjectType` representing either a `.workspace` or `.xcodeproj`.
    /// - Throws: `MappingError.noProjectsFound` if no recognizable project files are found.
    private static func determineProjectType(at path: AbsolutePath) throws -> ProjectType {
        switch path.fileExtension {
        case .xcworkspace:
            return .workspace(path)
        case .xcodeproj:
            return .xcodeProject(path)
        default:
            return try findProjectInDirectory(at: path)
        }
    }

    /// Searches a directory for the first `.xcworkspace` or `.xcodeproj` file.
    ///
    /// - Parameter path: A directory path.
    /// - Returns: A `ProjectType` if found.
    /// - Throws:
    ///   - `MappingError.noProjectsFound` if neither a `.xcworkspace` nor `.xcodeproj` is located in the directory.
    private static func findProjectInDirectory(at path: AbsolutePath) throws -> ProjectType {
        let contents = try FileManager.default.contentsOfDirectory(atPath: path.pathString)

        // Look for the first .xcworkspace
        if let workspaceName = contents.first(where: { $0.hasSuffix(".xcworkspace") }) {
            return .workspace(path.appending(component: workspaceName))
        }

        // Look for the first .xcodeproj
        if let projectName = contents.first(where: { $0.hasSuffix(".xcodeproj") }) {
            return .xcodeProject(path.appending(component: projectName))
        }

        throw MappingError.noProjectsFound
    }
}
