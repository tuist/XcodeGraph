import Foundation
import Path
import PathKit
import XcodeGraph
import XcodeProj
import FileSystem

// -----------------------------------------------------------------------------

// MARK: - Protocol

// -----------------------------------------------------------------------------

/// A protocol defining how to map a given file path to a `Graph`.
///
/// Conforming types handle:
/// - Checking if the path is valid.
/// - Determining if it’s a `.xcworkspace`, `.xcodeproj`, or a directory containing one.
/// - Building the final `Graph` by enumerating projects, targets, and dependencies.
public protocol XcodeGraphMapping {
    /// Maps the given file system path to a `Graph`.
    ///
    /// - Parameter pathString: A file path that might point to a `.xcworkspace`, `.xcodeproj`, or a directory.
    /// - Returns: A `Graph` representing the parsed Xcode workspace or project.
    /// - Throws: If the path is invalid or if no recognizable project/workspace is found.
    func map(at pathString: AbsolutePath) async throws -> Graph
}

// -----------------------------------------------------------------------------

// MARK: - Error Types

// -----------------------------------------------------------------------------

/// An error type for `XcodeGraphMapper` when the path is invalid or no projects are found.
public enum XcodeGraphMapperError: LocalizedError {
    case pathNotFound(String)
    case noProjectsFound(String)

    public var errorDescription: String? {
        switch self {
        case let .pathNotFound(path):
            return "The specified path does not exist: \(path)"
        case let .noProjectsFound(path):
            return "No `.xcworkspace` or `.xcodeproj` was found at: \(path)"
        }
    }
}

// -----------------------------------------------------------------------------

// MARK: - GraphType

// -----------------------------------------------------------------------------

/// Specifies whether we're mapping a single `.xcodeproj` or an `.xcworkspace`.
///
/// Unlike your old code, we no longer rely on `WorkspaceProvider` or `ProjectProvider`.
/// Instead, we directly store loaded `XcodeProj` / `XCWorkspace`.
enum XcodeMapperGraphType {
    case workspace(XCWorkspace)
    case project(XcodeProj)
}

// -----------------------------------------------------------------------------

// MARK: - Implementation

// -----------------------------------------------------------------------------

/// A unified mapper that:
/// 1. Detects `.xcworkspace` vs. `.xcodeproj` vs. directory
/// 2. Builds a `Graph` by enumerating projects, targets, and dependencies.
///
/// This replaces both:
/// - The old "GraphMapper" that enumerated projects
/// - The "ProjectParser" that detected the path type
/// - "ProjectProvider" / "WorkspaceProvider"
///
/// Example usage:
/// ```swift
/// let mapper: XcodeGraphMapping = XcodeGraphMapper()
/// let graph = try mapper.map(at: "/path/to/MyApp")
/// ```
public struct XcodeGraphMapper: XcodeGraphMapping {
    private let fileSystem: FileSystem

    // MARK: - Initialization

    public init(fileSystem: FileSystem = .init()) {
        self.fileSystem = fileSystem
    }

    // MARK: - Public API

    /// Maps the given file system path to a `Graph`, auto-detecting `.xcworkspace` or `.xcodeproj`
    /// and then enumerating all discovered projects & targets to build a final `Graph`.
    public func map(at path: AbsolutePath) async throws -> Graph {
        // 1. Verify path exists
        guard try await fileSystem.exists(path) else {
            throw XcodeGraphMapperError.pathNotFound(path.pathString)
        }

        // 2. Determine the GraphType (workspace or project) from the path
        let graphType = try await determineGraphType(at: path)

        // 3. Build & return the final Graph
        return try await buildGraph(from: graphType)
    }

    // MARK: - Private Helpers

    /// Examines the given path to see if it's:
    /// - A direct `.xcworkspace`,
    /// - A direct `.xcodeproj`,
    /// - Or a directory containing one.
    private func determineGraphType(at path: AbsolutePath) async throws -> XcodeMapperGraphType {
        // If the path has a file extension
        if let ext = path.extension?.lowercased() {
            switch ext {
            case "xcworkspace":
                let xcworkspace = try XCWorkspace(path: Path(path.pathString))
                return .workspace(xcworkspace)
            case "xcodeproj":
                let xcodeProj = try XcodeProj(pathString: path.pathString)
                return .project(xcodeProj)
            default:
                break
            }
        }

        // Otherwise, see if it's a directory containing .xcworkspace or .xcodeproj
        let contents = try fileSystem.glob(directory: path, include: ["**/*.xcworkspace", "**/*.xcodeproj"])
        // 1) Look for .xcworkspace
        if let workspacePath = try await contents.first(where: {
            $0.extension?.lowercased() == ".xcworkspace"
        }) {
            let xcworkspace = try XCWorkspace(path: Path(workspacePath.pathString))
            return .workspace(xcworkspace)
        }

        // 2) Look for .xcodeproj
        if let projectPath = try await contents.first(where: {
            $0.extension?.lowercased() == ".xcodeproj"
        }) {
            let xcodeProj = try XcodeProj(pathString: projectPath.pathString)
            return .project(xcodeProj)
        }

        throw XcodeGraphMapperError.noProjectsFound(path.pathString)
    }

    /// Builds the final `Graph` by enumerating the `.xcodeproj` or `.xcworkspace`.
    ///
    /// If it's a workspace, we gather all `.xcodeproj` references. If it's a single project,
    /// we treat it like a workspace with a single project. Then we load each project,
    /// map packages & targets, and build dependency edges. This merges logic from your old `GraphMapper`.
    func buildGraph(from graphType: XcodeMapperGraphType) async throws -> Graph {
        // A place to store discovered: path -> Project, packages, dependencies, etc.
        var projects: [AbsolutePath: Project] = [:]
        var packages: [AbsolutePath: [String: Package]] = [:]
        var dependencies: [GraphDependency: Set<GraphDependency>] = [:]
        var dependencyConditions: [GraphEdge: PlatformCondition] = [:]

        // Step 1: Identify all .xcodeproj paths in "the workspace" or the single .xcodeproj
        let projectPaths: [AbsolutePath]
        let graphName: String
        let workspacePath: AbsolutePath

        switch graphType {
        case let .workspace(xcworkspace):
            workspacePath = xcworkspace.workspacePath
            graphName = workspacePath.basenameWithoutExt

            // Gather all .xcodeproj references in the workspace
            let projectRefs = try await extractProjectPaths(
                from: xcworkspace.data.children,
                srcPath: workspacePath.parentDirectory
            )
            projectPaths = projectRefs.isEmpty ? [] : projectRefs

        case let .project(xcodeProj):
            let projPath = xcodeProj.projectPath
            workspacePath = projPath.parentDirectory
            graphName = "Workspace"
            // For a single .xcodeproj, treat it like a workspace with a single project
            projectPaths = [projPath]
        }

        // Step 2: Build a synthetic "Workspace" model for the final Graph
        let workspace = Workspace(
            path: workspacePath,
            xcWorkspacePath: workspacePath,
            name: graphName,
            projects: projectPaths
        )

        // Step 3: For each project path, load the .xcodeproj and map to a `Project`
        let projectResults = try workspace.projects.map { path -> (AbsolutePath, Project) in
            // Instead of "ProjectProvider", just load XcodeProj directly
            let xcodeProj = try XcodeProj(pathString: path.pathString)
            let projectMapper = PBXProjectMapper()
            let project = try projectMapper.map(xcodeProj: xcodeProj)
            return (path, project)
        }

        // Put them in our dictionary
        for (path, project) in projectResults {
            projects[path] = project
        }

        // Step 4: Build a map of all targets for target-based dependency resolution
        //         (like your old `allTargetsMap`)
        let allTargetsMap = Dictionary(
            projects.values.flatMap(\.targets),
            uniquingKeysWith: { existing, _ in existing }
        )

        // Step 5: Process dependencies for each project and target
        for (path, project) in projects {
            if !project.packages.isEmpty {
                packages[path] = Dictionary(uniqueKeysWithValues: project.packages.map { ($0.url, $0) })
            }

            for (name, target) in project.targets {
                let sourceDependency = GraphDependency.target(name: name, path: path.parentDirectory)
                let edgesAndDependencies = try target.dependencies.compactMap { targetDep -> (
                    GraphEdge,
                    PlatformCondition?,
                    GraphDependency
                ) in
                    let graphDep = try targetDep.graphDependency(
                        sourceDirectory: path.parentDirectory,
                        allTargetsMap: allTargetsMap
                    )
                    return (GraphEdge(from: sourceDependency, to: graphDep), targetDep.condition, graphDep)
                }

                for (edge, condition, _) in edgesAndDependencies {
                    if let condition {
                        dependencyConditions[edge] = condition
                    }
                }

                let targetDependencies = edgesAndDependencies.map(\.2)
                if !targetDependencies.isEmpty {
                    dependencies[sourceDependency] = Set(targetDependencies)
                }
            }
        }

        // Step 6: Assemble the final Graph
        return Graph(
            name: workspace.name,
            path: workspace.path,
            workspace: workspace,
            projects: projects,
            packages: packages,
            dependencies: dependencies,
            dependencyConditions: dependencyConditions
        )
    }

    // MARK: - Workspace Project Extraction (adapted from old XCWorkspaceMapper)

    /// Recursively identifies all `.xcodeproj` files within the workspace data elements.
    private func extractProjectPaths(
        from elements: [XCWorkspaceDataElement],
        srcPath: AbsolutePath
    ) async throws -> [AbsolutePath] {
        var paths = [AbsolutePath]()

        for element in elements {
            switch element {
            case let .file(ref):
                let refPath = try await ref.path(srcPath: srcPath)
                if refPath.extension == "xcodeproj" {
                    paths.append(refPath)
                }
            case let .group(group):
                // For nested groups, keep recursing
                let nestedRefs = try await extractProjectPaths(
                    from: group.children,
                    srcPath: srcPath
                )
                paths.append(contentsOf: nestedRefs)
            }
        }

        return paths
    }
}
