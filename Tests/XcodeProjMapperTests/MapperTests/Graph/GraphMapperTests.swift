import Path
import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeProjMapper

@Suite
struct XcodeGraphMapperTests {
    @Test("Maps a single project into a workspace graph")
    func testSingleProjectGraph() async throws {
        let pbxProj = PBXProj()
        let debug: XCBuildConfiguration = .testDebug().add(to: pbxProj)
        let releaseConfig: XCBuildConfiguration = .testRelease().add(to: pbxProj)
        let configurationList: XCConfigurationList = .test(buildConfigurations: [debug, releaseConfig]).add(to: pbxProj)
        let mockProvider = MockProjectProvider(
            sourceDirectory: "/tmp/SingleProject",
            projectName: "SingleProject",
            configurationList: configurationList,
            pbxProj: pbxProj
        )

        let sourceFile = try PBXFileReference.test(
            path: "ViewController.swift",
            lastKnownFileType: "sourcecode.swift"
        ).add(to: pbxProj).addToMainGroup(in: pbxProj)

        let buildFile = PBXBuildFile(file: sourceFile).add(to: pbxProj)
        let sourcesPhase = PBXSourcesBuildPhase(files: [buildFile]).add(to: pbxProj)

        // Add a single target to the project
        try PBXNativeTarget.test(
            name: "App",
            buildConfigurationList: configurationList,
            buildPhases: [sourcesPhase],
            productType: .application
        )
        .add(to: pbxProj)
        .add(to: pbxProj.rootObject)

        // Create a GraphType for a single project
        let projectPath = try AbsolutePath(validating: mockProvider.sourceDirectory.pathString)

        let mapper = XcodeGraphMapper()

        let graph = try await mapper.buildGraph(from: .project(mockProvider.xcodeProj))


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
        let pbxProjA = PBXProj()
        let pbxProjB = PBXProj()

        let debug: XCBuildConfiguration = .testDebug().add(to: pbxProjA).add(to: pbxProjB)
        let releaseConfig: XCBuildConfiguration = .testRelease().add(to: pbxProjA).add(to: pbxProjB)
        let configurationList: XCConfigurationList = .test(buildConfigurations: [debug, releaseConfig]).add(to: pbxProjA)
            .add(to: pbxProjB)

        // Setup two mock projects

        let mockProviderA = MockProjectProvider(
            sourceDirectory: "/tmp/Workspace/ProjectA",
            projectName: "ProjectA",
            configurationList: configurationList,
            pbxProj: pbxProjA
        )

        let mockProviderB = MockProjectProvider(
            sourceDirectory: "/tmp/Workspace/ProjectB",
            projectName: "ProjectB",
            configurationList: configurationList,
            pbxProj: pbxProjB
        )

        let sourceFile = try PBXFileReference.test(
            path: "ViewController.swift",
            lastKnownFileType: "sourcecode.swift"
        ).add(to: pbxProjA).addToMainGroup(in: pbxProjA)

        let buildFile = PBXBuildFile(file: sourceFile).add(to: pbxProjB)
        let sourcesPhase = PBXSourcesBuildPhase(files: [buildFile]).add(to: pbxProjB)

        // Add targets to each project
        try PBXNativeTarget.test(
            name: "ATarget",
            buildConfigurationList: configurationList,
            buildPhases: [sourcesPhase],
            productType: .framework
        )
        .add(to: pbxProjA)
        .add(to: pbxProjA.rootObject)

        try PBXNativeTarget.test(
            name: "BTarget",
            buildConfigurationList: configurationList,
            buildPhases: [sourcesPhase],
            productType: .framework
        )
        .add(to: pbxProjB)
        .add(to: pbxProjB.rootObject)

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

        let mapper = XcodeGraphMapper()

        let graph = try await mapper.buildGraph(from: .workspace(xcworkspace))


        // Validate the graph
        #expect(graph.workspace.name == "Workspace")
        #expect(graph.workspace.projects.contains(projectAPath) == true)
        #expect(graph.workspace.projects.contains(projectBPath) == true)
        #expect(graph.projects.count == 2)

        let projectA = try #require(graph.projects[projectAPath])
        let projectB = try #require(graph.projects[projectBPath])
        #expect(projectA.targets["ATarget"] != nil)
        #expect(projectB.targets["BTarget"] != nil)

        // No packages or dependencies
        #expect(graph.packages.isEmpty == true)
        #expect(graph.dependencies.isEmpty == true)
        #expect(graph.dependencyConditions.isEmpty == true)
    }

    @Test("Maps a project graph with dependencies between targets")
    func testGraphWithDependencies() async throws {
        let pbxProj = PBXProj()
        let debug: XCBuildConfiguration = .testDebug().add(to: pbxProj)
        let releaseConfig: XCBuildConfiguration = .testRelease().add(to: pbxProj)
        let configurationList: XCConfigurationList = .test(buildConfigurations: [debug, releaseConfig]).add(to: pbxProj)
        // Setup a single project with two targets: App depends on AFramework
        let mockProvider = MockProjectProvider(
            sourceDirectory: "/tmp/ProjectWithDeps",
            projectName: "ProjectWithDeps",
            configurationList: configurationList,
            pbxProj: pbxProj
        )

        let sourceFile = try PBXFileReference.test(
            path: "ViewController.swift",
            lastKnownFileType: "sourcecode.swift"
        ).add(to: pbxProj).addToMainGroup(in: pbxProj)

        let buildFile = PBXBuildFile(file: sourceFile).add(to: pbxProj)
        let sourcesPhase = PBXSourcesBuildPhase(files: [buildFile]).add(to: pbxProj)

        // Add a single target to the project
        let appTarget = try PBXNativeTarget.test(
            name: "App",
            buildConfigurationList: configurationList,
            buildPhases: [sourcesPhase],
            productType: .application
        )
        .add(to: pbxProj)
        .add(to: pbxProj.rootObject)

        // App -> AFramework dependency
        let target = try PBXNativeTarget.test(
            name: "AFramework",
            buildConfigurationList: configurationList,
            buildPhases: [sourcesPhase],
            productType: .framework
        ).add(to: pbxProj).add(to: pbxProj.rootObject)

        let dep = PBXTargetDependency(
            name: "AFramework",
            target: target
        )

        appTarget.dependencies.append(dep)

        let projectPath = try AbsolutePath(validating: mockProvider.xcodeProjPath.pathString)

        let mapper = XcodeGraphMapper()

        let graph = try await mapper.buildGraph(from: .project(mockProvider.xcodeProj))

        // Verify dependencies are mapped
        let sourceDep = GraphDependency.target(name: "App", path: mockProvider.sourceDirectory)
        let targetDep = GraphDependency.target(name: "AFramework", path: mockProvider.sourceDirectory)
        #expect(graph.dependencies == [sourceDep: [targetDep]])
    }
}
