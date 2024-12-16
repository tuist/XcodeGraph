import Path
import Testing
import XcodeGraph
import XcodeProj

@testable import TestSupport
@testable import XcodeProjToGraph

@Suite
struct GraphMapperTests {
    @Test("Maps a single project into a workspace graph")
    func testSingleProjectGraph() async throws {
        let mockProvider = MockProjectProvider(
            sourceDirectory: "/tmp/SingleProject",
            projectName: "SingleProject"
        )

        // Add a single target to the project
        let pbxProj = mockProvider.xcodeProj.pbxproj
        let target = PBXNativeTarget.mock(
            name: "App",
            productType: .application,
            pbxProj: pbxProj
        )
        if let project = pbxProj.projects.first {
            project.targets.append(target)
        }

        // Create a GraphType for a single project
        let projectPath = try AbsolutePath(validating: mockProvider.sourceDirectory.pathString)
        let graphType = GraphType.project(projectPath)

        // Mapper returns the mock provider for the given path
        let mapper = GraphMapper(graphType: graphType) { path in
            #expect(path == projectPath)
            return mockProvider
        }

        let graph = try await mapper.xcodeGraph()

        // Validate the graph
        #expect(graph.name == "Workspace")
        #expect(graph.projects.count == 1)
        #expect(graph.packages.isEmpty == true)
        #expect(graph.dependencies.isEmpty == true)
        #expect(graph.dependencyConditions.isEmpty == true)

        // Workspace should wrap the single project
        #expect(graph.workspace.projects.count == 1)
        #expect(graph.workspace.projects.first == projectPath)
        #expect(graph.workspace.name == "Workspace")
    }

    @Test("Maps a workspace with multiple projects into a single graph")
    func testWorkspaceGraphMultipleProjects() async throws {
        // Setup two mock projects
        let mockProviderA = MockProjectProvider(
            sourceDirectory: "/tmp/Workspace/ProjectA",
            projectName: "ProjectA"
        )
        let mockProviderB = MockProjectProvider(
            sourceDirectory: "/tmp/Workspace/ProjectB",
            projectName: "ProjectB"
        )

        // Add a target to Project A
        let pbxProjA = mockProviderA.xcodeProj.pbxproj
        let targetA = PBXNativeTarget.mock(
            name: "ATarget",
            productType: .framework,
            pbxProj: pbxProjA
        )
        if let projectA = pbxProjA.projects.first {
            projectA.targets.append(targetA)
        }

        // Add a target to Project B
        let pbxProjB = mockProviderB.xcodeProj.pbxproj
        let targetB = PBXNativeTarget.mock(
            name: "BTarget",
            productType: .framework,
            pbxProj: pbxProjB
        )
        if let projectB = pbxProjB.projects.first {
            projectB.targets.append(targetB)
        }

        // Set up a workspace referencing the two projects
        let workspacePath = try AbsolutePath(validating: "/tmp/Workspace")
        let projectAPath = try AbsolutePath(validating: "/tmp/Workspace/ProjectA.xcodeproj")
        let projectBPath = try AbsolutePath(validating: "/tmp/Workspace/ProjectB.xcodeproj")

        let xcworkspace = XCWorkspace(
            data: XCWorkspaceData(children: [
                .file(.init(location: .absolute(projectAPath.pathString))),
                .file(.init(location: .absolute(projectBPath.pathString))),
            ])
        )

        let provider = MockWorkspaceProvider(xcWorkspacePath: workspacePath, xcworkspace: xcworkspace)
        let graphType = GraphType.workspace(provider)

        // Mapper picks the correct provider based on path
        let mapper = GraphMapper(graphType: graphType) { path in
            if path == projectAPath {
                return mockProviderA
            } else if path == projectBPath {
                return mockProviderB
            } else {
                Issue.record("Unexpected project path requested: \(path)")
                throw MappingError.noProjectsFound(path: path.pathString)
            }
        }

        let graph = try await mapper.xcodeGraph()

        // Validate the graph
        #expect(graph.workspace.name == "Workspace")
        #expect(graph.workspace.projects.contains(projectAPath) == true)
        #expect(graph.workspace.projects.contains(projectBPath) == true)

        // Check that both projects appear in the graph
        #expect(graph.projects.count == 2)
        let projectA = try #require(graph.projects[projectAPath])
        let projectB = try #require(graph.projects[projectBPath])
        #expect(projectA.targets["ATarget"] != nil)
        #expect(projectB.targets["BTarget"] != nil)

        // No packages or dependencies were added
        #expect(graph.packages.isEmpty == true)
        #expect(graph.dependencies.isEmpty == true)
        #expect(graph.dependencyConditions.isEmpty == true)
    }

    @Test("Maps a project graph with dependencies between targets")
    func testGraphWithDependencies() async throws {
        // Setup a single project with two targets: App depends on AFramework
        let mockProvider = MockProjectProvider(
            sourceDirectory: "/tmp/ProjectWithDeps",
            projectName: "ProjectWithDeps"
        )
        let pbxProj = mockProvider.xcodeProj.pbxproj

        let frameworkTarget = PBXNativeTarget.mock(
            name: "AFramework",
            productType: .framework,
            pbxProj: pbxProj
        )

        let appTarget = PBXNativeTarget.mock(
            name: "App",
            productType: .application,
            pbxProj: pbxProj
        )

        // App -> AFramework dependency
        let dep = PBXTargetDependency.mockTargetDependency(
            name: "AFramework",
            pbxProj: pbxProj
        )
        appTarget.dependencies.append(dep)

        if let project = pbxProj.projects.first {
            project.targets.append(contentsOf: [frameworkTarget, appTarget])
        }

        let projectPath = try AbsolutePath(validating: mockProvider.xcodeProjPath.pathString)
        let graphType = GraphType.project(projectPath)

        let mapper = GraphMapper(graphType: graphType) { path in
            #expect(path == projectPath)
            return mockProvider
        }

        let graph = try await mapper.xcodeGraph()

        // Verify dependencies are mapped
        let sourceDep = GraphDependency.target(name: "App", path: mockProvider.sourceDirectory)
        let targetDep = GraphDependency.target(name: "AFramework", path: mockProvider.sourceDirectory)
        #expect(graph.dependencies == [sourceDep: [targetDep]])
    }
}
