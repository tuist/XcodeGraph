import FileSystem
import Foundation
import Path
import PathKit
import XcodeGraph
import XcodeProj

/// A protocol defining how to map a given file path to a `Graph`.
public protocol XcodeGraphMapping {
    func map(at pathString: AbsolutePath) async throws -> Graph
}

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

/// Specifies whether we're mapping a single `.xcodeproj` or an `.xcworkspace`.
enum XcodeMapperGraphType {
    case workspace(XCWorkspace)
    case project(XcodeProj)
}

///// A unified mapper that:
///// 1. Detects `.xcworkspace` vs. `.xcodeproj` vs. directory
///// 2. Builds a `Graph` by enumerating projects, targets, and dependencies.
/////
///// This replaces both:
///// - The old "GraphMapper" that enumerated projects
///// - The "ProjectParser" that detected the path type
///// - "ProjectProvider" / "WorkspaceProvider"
/////
///// Example usage:
///// ```swift
///// let mapper: XcodeGraphMapping = XcodeGraphMapper()
///// let graph = try mapper.map(at: "/path/to/MyApp")
///// ```
public struct XcodeGraphMapper: XcodeGraphMapping {
    private let fileSystem: FileSysteming

    // MARK: - Initialization

    public init(fileSystem: FileSysteming = FileSystem()) {
        self.fileSystem = fileSystem
    }

    // MARK: - Public API

    public func map(at path: AbsolutePath) async throws -> Graph {
        guard try await fileSystem.exists(path) else {
            throw XcodeGraphMapperError.pathNotFound(path.pathString)
        }

        let graphType = try await determineGraphType(at: path)
        return try await buildGraph(from: graphType)
    }

    // MARK: - Private Helpers

    private func determineGraphType(at path: AbsolutePath) async throws -> XcodeMapperGraphType {
        if let directType = try detectDirectGraphType(at: path) {
            return directType
        }
        return try await detectGraphTypeInDirectory(at: path)
    }

    private func detectDirectGraphType(at path: AbsolutePath) throws -> XcodeMapperGraphType? {
        guard let ext = path.extension?.lowercased() else { return nil }

        switch ext {
        case "xcworkspace":
            let xcworkspace = try XCWorkspace(path: Path(path.pathString))
            return .workspace(xcworkspace)
        case "xcodeproj":
            let xcodeProj = try XcodeProj(pathString: path.pathString)
            return .project(xcodeProj)
        default:
            return nil
        }
    }

    private func detectGraphTypeInDirectory(at path: AbsolutePath) async throws -> XcodeMapperGraphType {
        let contents = try fileSystem.glob(directory: path, include: ["**/*.xcworkspace", "**/*.xcodeproj"])

        if let workspacePath = try await contents.first(where: { $0.extension?.lowercased() == "xcworkspace" }) {
            let xcworkspace = try XCWorkspace(path: Path(workspacePath.pathString))
            return .workspace(xcworkspace)
        }

        if let projectPath = try await contents.first(where: { $0.extension?.lowercased() == "xcodeproj" }) {
            let xcodeProj = try XcodeProj(pathString: projectPath.pathString)
            return .project(xcodeProj)
        }

        throw XcodeGraphMapperError.noProjectsFound(path.pathString)
    }

    func buildGraph(from graphType: XcodeMapperGraphType) async throws -> Graph {
        let projectPaths = try await identifyProjectPaths(from: graphType)
        let workspace = assembleWorkspace(graphType: graphType, projectPaths: projectPaths)
        let projects = try await loadProjects(projectPaths)
        let packages = extractPackages(from: projects)
        let (dependencies, dependencyConditions) = try resolveDependencies(for: projects)

        return assembleFinalGraph(
            workspace: workspace,
            projects: projects,
            packages: packages,
            dependencies: dependencies,
            dependencyConditions: dependencyConditions
        )
    }

    private func identifyProjectPaths(from graphType: XcodeMapperGraphType) async throws -> [AbsolutePath] {
        switch graphType {
        case let .workspace(xcworkspace):
            return try await extractProjectPaths(
                from: xcworkspace.data.children,
                srcPath: xcworkspace.workspacePath.parentDirectory
            )
        case let .project(xcodeProj):
            return [xcodeProj.projectPath]
        }
    }

    private func assembleWorkspace(graphType: XcodeMapperGraphType, projectPaths: [AbsolutePath]) -> Workspace {
        let workspacePath: AbsolutePath
        let name: String

        switch graphType {
        case let .workspace(xcworkspace):
            workspacePath = xcworkspace.workspacePath
            name = workspacePath.basenameWithoutExt
        case let .project(xcodeProj):
            workspacePath = xcodeProj.projectPath.parentDirectory
            name = "Workspace"
        }

        return Workspace(
            path: workspacePath,
            xcWorkspacePath: workspacePath,
            name: name,
            projects: projectPaths
        )
    }

    private func loadProjects(_ projectPaths: [AbsolutePath]) async throws -> [AbsolutePath: Project] {
        var projects: [AbsolutePath: Project] = [:]

        for path in projectPaths {
            let xcodeProj = try XcodeProj(pathString: path.pathString)
            let projectMapper = PBXProjectMapper()
            let project = try await projectMapper.map(xcodeProj: xcodeProj)
            projects[path] = project
        }

        return projects
    }

    private func extractPackages(from projects: [AbsolutePath: Project]) -> [AbsolutePath: [String: Package]] {
        var packages: [AbsolutePath: [String: Package]] = [:]

        for (path, project) in projects {
            if !project.packages.isEmpty {
                packages[path] = Dictionary(uniqueKeysWithValues: project.packages.map { ($0.url, $0) })
            }
        }

        return packages
    }

    private func resolveDependencies(
        for projects: [AbsolutePath: Project]
    ) throws -> (
        [GraphDependency: Set<GraphDependency>],
        [GraphEdge: PlatformCondition]
    ) {
        let allTargetsMap = Dictionary(
            projects.values.flatMap(\.targets),
            uniquingKeysWith: { existing, _ in existing }
        )
        return try buildDependencies(for: projects, using: allTargetsMap)
    }

    private func buildDependencies(
        for projects: [AbsolutePath: Project],
        using allTargetsMap: [String: Target]
    ) throws -> (
        [GraphDependency: Set<GraphDependency>],
        [GraphEdge: PlatformCondition]
    ) {
        let result = try projects.reduce(into: (
            dependencies: [GraphDependency: Set<GraphDependency>](),
            conditions: [GraphEdge: PlatformCondition]()
        )) { partial, entry in
            let (path, project) = entry

            try project.targets.forEach { name, target in
                let sourceDependency = GraphDependency.target(name: name, path: path)

                // Convert target dependencies into edges
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

                // Update the conditions dictionary
                for (edge, condition, _) in edgesAndDependencies {
                    if let condition {
                        partial.conditions[edge] = condition
                    }
                }

                // Update the dependencies dictionary
                let targetDependencies = edgesAndDependencies.map(\.2)
                if !targetDependencies.isEmpty {
                    partial.dependencies[sourceDependency] = Set(targetDependencies)
                }
            }
        }

        return (result.dependencies, result.conditions)
    }

    private func assembleFinalGraph(
        workspace: Workspace,
        projects: [AbsolutePath: Project],
        packages: [AbsolutePath: [String: Package]],
        dependencies: [GraphDependency: Set<GraphDependency>],
        dependencyConditions: [GraphEdge: PlatformCondition]
    ) -> Graph {
        Graph(
            name: workspace.name,
            path: workspace.path,
            workspace: workspace,
            projects: projects,
            packages: packages,
            dependencies: dependencies,
            dependencyConditions: dependencyConditions
        )
    }

    private func extractProjectPaths(
        from elements: [XCWorkspaceDataElement],
        srcPath: AbsolutePath
    ) async throws -> [AbsolutePath] {
        var paths: [AbsolutePath] = []

        for element in elements {
            switch element {
            case let .file(ref):
                let refPath = try await ref.path(srcPath: srcPath)
                if refPath.extension == "xcodeproj" {
                    paths.append(refPath)
                }
            case let .group(group):
                let nestedPaths = try await extractProjectPaths(from: group.children, srcPath: srcPath)
                paths.append(contentsOf: nestedPaths)
            }
        }

        return paths
    }
}
