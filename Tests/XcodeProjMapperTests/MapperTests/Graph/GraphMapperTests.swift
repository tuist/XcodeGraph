import Foundation
import Path
import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeProjMapper

@Suite
struct XcodeGraphMapperTests {
    @Test("Maps a single project into a workspace graph")
    func testSingleProjectGraph() async throws {
        // Given
        let pbxProj = PBXProj()
        let debug: XCBuildConfiguration = .testDebug().add(to: pbxProj)
        let releaseConfig: XCBuildConfiguration = .testRelease().add(to: pbxProj)
        let configurationList: XCConfigurationList = .test(buildConfigurations: [debug, releaseConfig])
            .add(to: pbxProj)

        let tempDirectory = FileManager.default.temporaryDirectory

        let mockProvider = MockProjectProvider(
            sourceDirectory: tempDirectory.path,
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

        let projectPath = mockProvider.xcodeProj.projectPath
        try mockProvider.xcodeProj.write(path: mockProvider.xcodeProj.path!)
        let mapper = XcodeGraphMapper()
        // When
        let graph = try await mapper.buildGraph(from: .project(mockProvider.xcodeProj))

        // Then
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
        // Given
        let pbxProjA = PBXProj()
        let pbxProjB = PBXProj()
        let sourceDirectory = FileManager.default.temporaryDirectory.path

        let debug: XCBuildConfiguration = .testDebug().add(to: pbxProjA).add(to: pbxProjB)
        let releaseConfig: XCBuildConfiguration = .testRelease().add(to: pbxProjA).add(to: pbxProjB)
        let configurationList: XCConfigurationList = .test(
            buildConfigurations: [debug, releaseConfig]
        )
        .add(to: pbxProjA)
        .add(to: pbxProjB)

        let mockProviderA = MockProjectProvider(
            sourceDirectory: sourceDirectory,
            projectName: "ProjectA",
            configurationList: configurationList,
            pbxProj: pbxProjA
        )
        let projectA = mockProviderA.xcodeProj

        let mockProviderB = MockProjectProvider(
            sourceDirectory: sourceDirectory,
            projectName: "ProjectB",
            configurationList: configurationList,
            pbxProj: pbxProjB
        )
        let projectB = mockProviderB.xcodeProj

        let sourceFile = try PBXFileReference.test(
            path: "ViewController.swift",
            lastKnownFileType: "sourcecode.swift"
        ).add(to: pbxProjA).addToMainGroup(in: pbxProjA)

        let buildFile = PBXBuildFile(file: sourceFile).add(to: pbxProjB).add(to: pbxProjA)
        let sourcesPhase = PBXSourcesBuildPhase(files: [buildFile]).add(to: pbxProjB).add(to: pbxProjA)

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

        let projectAPath = try #require(projectA.path?.string)
        let projectBPath = try #require(projectB.path?.string)

        let xcworkspace = XCWorkspace(
            data: XCWorkspaceData(
                children: [
                    .file(.init(location: .absolute(projectAPath))),
                    .file(.init(location: .absolute(projectBPath))),
                ]
            ),
            path: .init(sourceDirectory.appending("/Workspace.xcworkspace"))
        )

        try projectA.write(path: projectA.path!)
        try projectB.write(path: projectB.path!)
        let mapper = XcodeGraphMapper()

        // When
        let graph = try await mapper.buildGraph(from: .workspace(xcworkspace))
        print(projectA.path!)
        // Then
        #expect(graph.workspace.name == "Workspace")
        #expect(graph.workspace.projects.contains(projectA.projectPath) == true)
        #expect(graph.workspace.projects.contains(projectB.projectPath) == true)
        #expect(graph.projects.count == 2)

        let mappedProjectA = try #require(graph.projects[projectA.projectPath])
        let mappedProjectB = try #require(graph.projects[projectB.projectPath])
        #expect(mappedProjectA.targets["ATarget"] != nil)
        #expect(mappedProjectB.targets["BTarget"] != nil)

        // No packages or dependencies
        #expect(graph.packages.isEmpty == true)
        #expect(graph.dependencies.isEmpty == true)
        #expect(graph.dependencyConditions.isEmpty == true)
    }

    @Test("Maps a project graph with dependencies between targets")
    func testGraphWithDependencies() async throws {
        // Given
        let pbxProj = PBXProj()
        let debug: XCBuildConfiguration = .testDebug().add(to: pbxProj)
        let releaseConfig: XCBuildConfiguration = .testRelease().add(to: pbxProj)
        let configurationList: XCConfigurationList = .test(
            buildConfigurations: [debug, releaseConfig]
        )
        .add(to: pbxProj)

        let sourceDirectory = FileManager.default.temporaryDirectory.path

        let mockProvider = MockProjectProvider(
            sourceDirectory: sourceDirectory,
            projectName: "ProjectWithDeps",
            configurationList: configurationList,
            pbxProj: pbxProj
        )

        let sourceFile = try PBXFileReference.test(
            path: "ViewController.swift",
            lastKnownFileType: "sourcecode.swift"
        )
        .add(to: pbxProj)
        .addToMainGroup(in: pbxProj)

        let buildFile = PBXBuildFile(file: sourceFile).add(to: pbxProj)
        let sourcesPhase = PBXSourcesBuildPhase(files: [buildFile]).add(to: pbxProj)

        let appTarget = try PBXNativeTarget.test(
            name: "App",
            buildConfigurationList: configurationList,
            buildPhases: [sourcesPhase],
            productType: .application
        )
        .add(to: pbxProj)
        .add(to: pbxProj.rootObject)

        // App -> AFramework dependency
        let frameworkTarget = try PBXNativeTarget.test(
            name: "AFramework",
            buildConfigurationList: configurationList,
            buildPhases: [sourcesPhase],
            productType: .framework
        )
        .add(to: pbxProj)
        .add(to: pbxProj.rootObject)

        let dep = PBXTargetDependency(
            name: "AFramework",
            target: frameworkTarget
        )
        .add(to: pbxProj)
        appTarget.dependencies.append(dep)
        try mockProvider.xcodeProj.write(path: mockProvider.xcodeProj.path!)
        let mapper = XcodeGraphMapper()

        // When
        let graph = try await mapper.buildGraph(from: .project(mockProvider.xcodeProj))

        // Then
        // Verify dependencies are mapped
        let targetDep = GraphDependency.target(name: "AFramework", path: mockProvider.xcodeProj.srcPath)
        let expectedDependency = try #require(graph.dependencies.first?.value)

        #expect(expectedDependency == [targetDep])
    }
}
