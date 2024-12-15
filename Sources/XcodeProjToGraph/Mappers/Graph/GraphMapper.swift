import Foundation
import Path
import PathKit
import XcodeGraph
import XcodeProj

/// Specifies the type of graph to generate.
///
/// - `.workspace(WorkspaceProviding)`: Constructs a graph from a workspace provided by a type conforming to `WorkspaceProviding`.
/// - `.project(AbsolutePath)`: Constructs a graph from a single project located at the given path, treating it as a workspace
/// with one project.
public enum GraphType: Sendable {
    case workspace(WorkspaceProviding)
    case project(AbsolutePath)
}

/// A mapper that constructs a complete `XcodeGraph.Graph` from a given workspace or project.
///
/// This mapper aggregates data from projects, packages, and dependencies to produce a fully
/// formed graph. It resolves each project, maps targets, packages, and dependencies, and then
/// assembles them into a final `XcodeGraph.Graph` model.
///
/// The resulting graph can be used for analysis, generation of derived artifacts, or other
/// tooling tasks.
///
/// Typical usage involves creating a `GraphMapper` with a specified `GraphType` and then calling
/// `xcodeGraph()` to produce the graph.
public final class GraphMapper: Sendable {
    private let projectProviderClosure: @Sendable (AbsolutePath) async throws -> ProjectProviding
    public let graphType: GraphType

    /// Initializes the mapper with a specified graph type and an optional project provider closure.
    ///
    /// - Parameters:
    ///   - graphType: The type of graph (workspace or project) to map.
    ///   - projectProviderClosure: A closure that, given a project path, returns a `ProjectProviding`.
    ///     By default, it initializes a `ProjectProvider` from the given `AbsolutePath`.
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

    /// Constructs an `XcodeGraph.Graph` by mapping all projects, packages, and dependencies within the specified workspace or
    /// project.
    ///
    /// - Returns: A fully mapped `XcodeGraph.Graph` containing projects, packages, dependencies, and conditions.
    /// - Throws: An error if project mapping or dependency resolution fails.
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

        let projectResults = try await workspace.projects.lazy.asyncCompactMap { path in
            do {
                let provider = try await self.projectProviderClosure(path)
                let projectMapper = ProjectMapper(projectProvider: provider)
                let project = try await projectMapper.mapProject()
                return (path, provider, project)
            } catch {
                return nil
            }
        }

        for (path, provider, project) in projectResults {
            projectProviders[path] = provider
            projects[path] = project
        }

        let allTargetsMap = Dictionary(
            projects.values.flatMap(\.targets),
            uniquingKeysWith: { existing, _ in
                existing
            }
        )

        for (path, project) in projects {
            if !project.packages.isEmpty {
                packages[path] = Dictionary(
                    uniqueKeysWithValues: project.packages.map { ($0.url, $0) }
                )
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
