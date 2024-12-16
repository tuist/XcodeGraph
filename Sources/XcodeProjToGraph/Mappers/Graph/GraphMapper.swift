import Foundation
import Path
import PathKit
import XcodeGraph
import XcodeProj

/// Specifies the type of graph to generate for code analysis or tooling tasks.
///
/// `GraphType` allows you to choose whether to build a graph from a single project or from an entire workspace:
/// - `.workspace(WorkspaceProviding)`: Constructs a graph from a workspace (potentially containing multiple projects).
/// - `.project(AbsolutePath)`: Constructs a graph from a single project at the given path, treating it as a workspace with one
/// project.
public enum GraphType: Sendable {
    case workspace(WorkspaceProviding)
    case project(AbsolutePath)
}

/// A mapper that constructs a complete `XcodeGraph.Graph` from a given workspace or project.
///
/// `GraphMapper` orchestrates the process of aggregating data from all relevant sources:
/// - Projects (via `ProjectMapper`),
/// - Targets, Packages, and Dependencies (translated into a uniform graph model),
/// - Platform-specific conditions for dependencies (e.g., iOS-only frameworks),
///
/// The resulting `XcodeGraph.Graph` model can be used for:
/// - Dependency analysis: Understand how targets and packages interrelate.
/// - Code generation: Produce derived artifacts, such as resource accessors or configuration files.
/// - Tooling integration: Serve as input to custom build tools, linters, or visualizers.
///
/// **Example Usage:**
/// ```swift
/// // Suppose you have a WorkspaceProvider for a workspace:
/// let workspaceProvider: WorkspaceProviding = ...
/// let graphMapper = GraphMapper(graphType: .workspace(workspaceProvider))
///
/// // Or, for a single project:
/// let projectPath: AbsolutePath = ...
/// let graphMapper = GraphMapper(graphType: .project(projectPath))
///
/// // Construct the graph:
/// let graph = try await graphMapper.xcodeGraph()
///
/// // 'graph' now contains a unified representation of projects, targets, packages, and dependencies.
/// // You can analyze it, generate code, or integrate it with other developer tools.
/// ```
public final class GraphMapper: Sendable {
    // MARK: - Properties

    private let projectProviderClosure: @Sendable (AbsolutePath) async throws -> ProjectProviding
    public let graphType: GraphType

    // MARK: - Initialization

    /// Initializes the mapper with a specified `GraphType` and an optional project provider closure.
    ///
    /// The `projectProviderClosure` allows for custom logic when creating `ProjectProviding` instances. By default,
    /// it initializes a `ProjectProvider` from the given path.
    ///
    /// - Parameters:
    ///   - graphType: The type of graph to build (workspace or project).
    ///   - projectProviderClosure: A closure that returns a `ProjectProviding` instance for a given project path.
    ///     If not provided, a default closure is used that instantiates a `ProjectProvider` from the given path.
    public init(
        graphType: GraphType,
        projectProviderClosure: @escaping @Sendable (AbsolutePath) async throws -> ProjectProviding = {
            let xcodeProj = try XcodeProj(pathString: $0.pathString)
            return ProjectProvider(xcodeProjPath: $0, xcodeProj: xcodeProj)
        }
    ) {
        self.graphType = graphType
        self.projectProviderClosure = projectProviderClosure
    }

    // MARK: - Mapping Logic

    /// Constructs an `XcodeGraph.Graph` by mapping all projects, packages, and dependencies from the specified workspace or
    /// project.
    ///
    /// This method:
    /// 1. Builds a `Workspace` model from either a workspace or a single project.
    /// 2. For each project in the workspace, uses `ProjectMapper` to produce a `Project` model.
    /// 3. Aggregates all projects, packages, targets, and dependencies into a single `Graph`.
    /// 4. Attaches platform conditions to edges, respecting platform-specific dependencies.
    ///
    /// - Returns: A fully mapped `Graph` containing all discovered projects, packages, dependencies, and conditions.
    /// - Throws: If mapping projects, packages, or dependencies fails (e.g., due to missing files or invalid settings).
    public func xcodeGraph() async throws -> XcodeGraph.Graph {
        var projectProviders = [AbsolutePath: ProjectProviding]()
        var projects: [AbsolutePath: Project] = [:]
        var packages: [AbsolutePath: [String: Package]] = [:]
        var dependencies: [GraphDependency: Set<GraphDependency>] = [:]
        var dependencyConditions: [GraphEdge: PlatformCondition] = [:]

        let workspace =
            switch graphType {
            case let .workspace(workspaceProvider):
                try await WorkspaceMapper(workspaceProvider: workspaceProvider).map()
            case let .project(absolutePath):
                Workspace(
                    path: absolutePath.parentDirectory,
                    xcWorkspacePath: absolutePath.parentDirectory,
                    name: "Workspace",
                    projects: [absolutePath]
                )
            }

        // Map each project in the workspace
        let projectResults = try await workspace.projects.lazy.asyncCompactMap { path in
            do {
                let provider = try await self.projectProviderClosure(path)
                let projectMapper = ProjectMapper(projectProvider: provider)
                let project = try await projectMapper.mapProject()
                return (path, provider, project)
            } catch {
                // If one project fails to map, it's skipped. Consider logging this or throwing an error for strict usage.
                return nil
            }
        }

        for (path, provider, project) in projectResults {
            projectProviders[path] = provider
            projects[path] = project
        }

        // Build a map of all targets for easy target-based dependency resolution
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
                let edgesAndDependencies = try await target.dependencies.asyncCompactMap { targetDep in
                    let graphDep = try await targetDep.graphDependency(
                        sourceDirectory: path.parentDirectory,
                        allTargetsMap: allTargetsMap
                    )
                    let edge = GraphEdge(from: sourceDependency, to: graphDep)
                    return (edge, targetDep.condition, graphDep)
                }

                for (edge, condition, _) in edgesAndDependencies {
                    dependencyConditions[edge] = condition
                }

                let targetDependencies = edgesAndDependencies.compactMap(\.2)
                guard !targetDependencies.isEmpty else { continue }
                dependencies[sourceDependency] = Set(targetDependencies)
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
