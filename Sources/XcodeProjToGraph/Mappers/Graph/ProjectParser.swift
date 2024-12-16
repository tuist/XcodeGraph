import Foundation
import Path
import XcodeGraph
import XcodeProj

/// Specifies the type of project to parse based on the discovered file structure.
///
/// `ProjectType` is determined by examining the path or directory contents:
/// - `.workspace(path)`: Indicates a `.xcworkspace` is present at the given path.
/// - `.xcodeProject(path)`: Indicates a `.xcodeproj` is present at the given path.
public enum ProjectType {
    case workspace(AbsolutePath)
    case xcodeProject(AbsolutePath)
}

/// A parser responsible for identifying and parsing Xcode projects or workspaces into a `Graph` model.
///
/// `ProjectParser` determines whether the given path points to:
/// - A `.xcworkspace` file
/// - A `.xcodeproj` file
/// - Or a directory containing one of these project types
///
/// Once the project type is identified, `ProjectParser` delegates the actual mapping to `GraphMapper`,
/// resulting in a unified `Graph` model that includes targets, packages, and dependencies.
///
/// **Example Usage:**
/// ```swift
/// // Given a file system path, which could be a directory, .xcodeproj, or .xcworkspace:
/// let path = "/path/to/MyApp"
///
/// do {
///     // Parse the project or workspace at the given path into a Graph.
///     let graph = try await ProjectParser.parse(atPath: path)
///
///     // 'graph' now contains a comprehensive model of the project's structure, including targets,
///     // dependencies, and associated packages. This can be used for analysis, code generation, or tooling.
/// } catch {
///     // Handle errors such as missing projects or unreadable files.
///     print("Failed to parse project: \(error)")
/// }
/// ```
public class ProjectParser {
    public init() {}

    /// Parses the project or workspace at the given file system path into a `Graph`.
    ///
    /// Attempts to locate a `.xcworkspace` or `.xcodeproj` at or within the provided path.
    /// If both are absent, it throws an error indicating no projects were found.
    ///
    /// - Parameter path: The file system path to a `.xcworkspace`, `.xcodeproj`, or a directory containing one.
    /// - Returns: A `Graph` representing the parsed project structure, including targets, dependencies, and packages.
    /// - Throws:
    ///   - `MappingError.pathNotFound` if the given path does not exist.
    ///   - `MappingError.noProjectsFound` if no `.xcworkspace` or `.xcodeproj` is located.
    ///   - Other errors thrown by `GraphMapper` during graph construction.
    public static func parse(atPath path: String) async throws -> Graph {
        guard FileManager.default.fileExists(atPath: path) else {
            throw MappingError.pathNotFound(path: path)
        }

        let absolutePath = try AbsolutePath(validating: path)
        let type = try determineProjectType(at: absolutePath)
        return try await parse(projectType: type)
    }

    /// Parses a given `ProjectType` (workspace or project) into a `Graph`.
    ///
    /// - Parameter projectType: The identified `ProjectType`.
    /// - Returns: A `Graph` model representing the parsed structure.
    /// - Throws: Any errors encountered during graph mapping, including missing files or invalid configurations.
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
    /// This treats the project as a mini-workspace containing a single project, enabling consistent handling by `GraphMapper`.
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
    /// If the workspace references multiple projects, they are all integrated into a single graph.
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
    /// If none are found, `MappingError.noProjectsFound` is thrown. This indicates that the provided directory
    /// does not contain a recognizable Xcode project or workspace, and thus cannot be parsed.
    ///
    /// - Parameter path: The directory path to search.
    /// - Returns: A `ProjectType` if a project is found.
    /// - Throws: `MappingError.noProjectsFound` if no `.xcworkspace` or `.xcodeproj` is detected.
    private static func findProjectInDirectory(at path: AbsolutePath) throws -> ProjectType {
        let contents = try FileManager.default.contentsOfDirectory(atPath: path.pathString)

        // Search for a .xcworkspace
        if let workspaceName = contents.first(where: { $0.lowercased().hasSuffix(".xcworkspace") }) {
            return .workspace(path.appending(component: workspaceName))
        }

        // Search for a .xcodeproj
        if let projectName = contents.first(where: { $0.lowercased().hasSuffix(".xcodeproj") }) {
            return .xcodeProject(path.appending(component: projectName))
        }

        // No projects found in this directory
        throw MappingError.noProjectsFound(path: path.pathString)
    }
}
