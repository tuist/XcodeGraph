import Foundation
import Path
import XcodeGraph
import XcodeProj

/// A protocol defining how to parse a project or workspace path into a `Graph` model.
public protocol ProjectParsing {
    /// Parses the project or workspace at the given file system path into a `Graph`.
    ///
    /// This method analyzes the provided path to determine whether it points to:
    /// - A `.xcworkspace` file
    /// - A `.xcodeproj` file
    /// - A directory containing either of these project types
    ///
    /// Once identified, it constructs a `Graph` model representing the entire project structure,
    /// including targets, dependencies, and packages. This `Graph` can then be used for tasks such as
    /// code generation, dependency analysis, or integration with custom developer tooling.
    ///
    /// **Example Usage:**
    /// ```swift
    /// // Suppose `/path/to/MyApp` contains either a MyApp.xcworkspace or MyApp.xcodeproj:
    /// let parser: ProjectParsing = ProjectParser()
    /// let graph = try parser.parse(at: "/path/to/MyApp")
    ///
    /// // 'graph' now represents the entire project's structure.
    /// // You can analyze dependencies, generate derived code, or feed it into other build tools.
    /// ```
    ///
    /// If the specified path does not exist or no recognized Xcode project files are found,
    /// this method will throw an error.
    ///
    /// - Parameter path: A file system path to a `.xcworkspace`, `.xcodeproj`, or a directory containing one.
    /// - Returns: A `Graph` representing the discovered project or workspace.
    /// - Throws: If no project or workspace can be found at the provided path or if other
    ///           internal parsing or mapping steps fail.
    func parse(at path: String) throws -> Graph
}

/// Specifies the type of project to parse:
/// - `.workspace(path)`: A `.xcworkspace` found at `path`
/// - `.xcodeProject(path)`: A `.xcodeproj` found at `path`
enum ProjectType: Equatable {
    case workspace(AbsolutePath)
    case xcodeProject(AbsolutePath)
}

/// Errors that can occur when parsing a project or workspace.
enum ProjectParserError: LocalizedError, Equatable {
    case pathNotFound(path: String)
    case noProjectsFound(path: String)

    var errorDescription: String? {
        switch self {
        case let .pathNotFound(path):
            return "The specified path does not exist: \(path)"
        case let .noProjectsFound(path):
            return "No `.xcworkspace` or `.xcodeproj` was found at: \(path)"
        }
    }
}

/// A parser for identifying and parsing Xcode projects or workspaces into a `Graph` model.
///
/// `ProjectParser` determines whether a given path points to a `.xcworkspace`, `.xcodeproj`,
/// or a directory containing one. It then uses a `GraphMapper` to build a unified `Graph` model
/// from the discovered projects. The resulting `Graph` can be employed for a wide range of tasks:
/// dependency analysis, code generation, custom tooling integration, and more.
public struct ProjectParser: ProjectParsing {
    private let fileManager: FileManager

    /// Creates a new `ProjectParser`.
    ///
    /// - Parameter fileManager: The file manager to use for file system queries. Defaults to `.default`.
    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func parse(at path: String) throws -> Graph {
        guard fileManager.fileExists(atPath: path) else {
            throw ProjectParserError.pathNotFound(path: path)
        }

        let absolutePath = try AbsolutePath(validating: path)
        let type = try determineProjectType(at: absolutePath)
        return try parse(projectType: type)
    }

    // MARK: - Internal Helpers

    func parse(projectType: ProjectType) throws -> Graph {
        switch projectType {
        case let .workspace(path):
            return try mapXCWorkspace(at: path)
        case let .xcodeProject(path):
            return try mapXcodeProj(at: path)
        }
    }

    func determineProjectType(at path: AbsolutePath) throws -> ProjectType {
        switch path.fileExtension {
        case .xcworkspace:
            return .workspace(path)
        case .xcodeproj:
            return .xcodeProject(path)
        default:
            return try findProjectInDirectory(at: path)
        }
    }

    private func mapXcodeProj(at path: AbsolutePath) throws -> Graph {
        let graphMapper = GraphMapper(graphType: .project(path))
        return try graphMapper.map()
    }

    private func mapXCWorkspace(at path: AbsolutePath) throws -> Graph {
        let workspaceProvider = try WorkspaceProvider(xcWorkspacePath: path)
        let graphMapper = GraphMapper(graphType: .workspace(workspaceProvider))
        return try graphMapper.map()
    }

    private func findProjectInDirectory(at path: AbsolutePath) throws -> ProjectType {
        let contents = try fileManager.contentsOfDirectory(atPath: path.pathString)

        if let workspaceName = contents.first(where: { $0.lowercased().hasSuffix(".xcworkspace") }) {
            return .workspace(path.appending(component: workspaceName))
        }

        if let projectName = contents.first(where: { $0.lowercased().hasSuffix(".xcodeproj") }) {
            return .xcodeProject(path.appending(component: projectName))
        }

        throw ProjectParserError.noProjectsFound(path: path.pathString)
    }
}
