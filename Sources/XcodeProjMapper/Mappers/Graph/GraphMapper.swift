import Foundation
import Path
import PathKit
import XcodeGraph
import XcodeProj

/// A protocol that defines how to construct a `Graph` from either a workspace or a project.
protocol GraphMapping {
    /// Constructs a `Graph` by analyzing the provided workspace or project.
    ///
    /// - Returns: A fully constructed `XcodeGraph.Graph`.
    /// - Throws: If reading or mapping any of the projects or dependencies fails.
    func map() throws -> XcodeGraph.Graph
}

/// Specifies the type of graph to generate for analysis or tooling tasks.
///
/// - `.workspace(WorkspaceProviding)`: Build a graph from a workspace, potentially containing multiple projects.
/// - `.project(AbsolutePath)`: Build a graph from a single `.xcodeproj` located at the given path.
enum GraphType {
    case workspace(WorkspaceProviding)
    case project(AbsolutePath)
}

/// A mapper that constructs a `XcodeGraph.Graph` from a workspace or project.
///
/// `GraphMapper` aggregates projects, packages, and targets into a unified graph model suitable for:
/// - Dependency analysis
/// - Code generation
/// - Integration with developer tools
///
/// Example:
/// ```swift
/// let workspaceProvider: WorkspaceProviding = ...
/// let graphMapper = GraphMapper(graphType: .workspace(workspaceProvider))
///
/// let graph = try graphMapper.map()
/// // 'graph' now represents all projects, targets, and dependencies in the workspace.
/// ```
struct GraphMapper: GraphMapping {
    private let projectProviderClosure: (AbsolutePath) throws -> ProjectProviding
    private let graphType: GraphType

    /// Initializes the mapper with a given `GraphType` and optionally a custom project provider closure.
    ///
    /// - Parameters:
    ///   - graphType: The type of graph to construct.
    ///   - projectProviderClosure: A closure for creating `ProjectProviding` instances from paths.
    ///     Defaults to creating a `ProjectProvider` directly from `XcodeProj`.
    init(
        graphType: GraphType,
        projectProviderClosure: @escaping (AbsolutePath) throws -> ProjectProviding = { path in
            let xcodeProj = try XcodeProj(pathString: path.pathString)
            return ProjectProvider(xcodeProjPath: path, xcodeProj: xcodeProj)
        }
    ) {
        self.graphType = graphType
        self.projectProviderClosure = projectProviderClosure
    }

    func map() throws -> XcodeGraph.Graph {
        var projects: [AbsolutePath: Project] = [:]
        var packages: [AbsolutePath: [String: Package]] = [:]
        var dependencies: [GraphDependency: Set<GraphDependency>] = [:]
        var dependencyConditions: [GraphEdge: PlatformCondition] = [:]

        let workspace: Workspace = try {
            switch graphType {
            case let .workspace(workspaceProvider):
                return try XCWorkspaceMapper().map(workspaceProvider: workspaceProvider)
            case let .project(absolutePath):
                return Workspace(
                    path: absolutePath.parentDirectory,
                    xcWorkspacePath: absolutePath.parentDirectory,
                    name: "Workspace",
                    projects: [absolutePath]
                )
            }
        }()

        // Map each project in the workspace. Fail early if one fails.
        let projectResults = try workspace.projects.map { path -> (AbsolutePath, Project) in
            let provider = try projectProviderClosure(path)
            let projectMapper = PBXProjectMapper()
            let project = try projectMapper.map(projectProvider: provider)
            return (path, project)
        }

        for (path, project) in projectResults {
            projects[path] = project
        }

        // Build a map of all targets for target-based dependency resolution
        let allTargetsMap = Dictionary(
            projects.values.flatMap(\.targets),
            uniquingKeysWith: { existing, _ in existing }
        )

        // Process dependencies for each project and target
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

        // Return the assembled graph
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
}
