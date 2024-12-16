import Foundation
import Path
import Testing
import XcodeGraph
import XcodeProj

@testable import XcodeProjToGraph

public struct MockWorkspaceProvider: WorkspaceProviding {
    public var workspaceDirectory: AbsolutePath
    public var xcWorkspacePath: AbsolutePath
    public var xcworkspace: XCWorkspace

    public init(xcWorkspacePath: AbsolutePath, xcworkspace: XCWorkspace) {
        self.xcWorkspacePath = xcWorkspacePath
        workspaceDirectory = xcWorkspacePath.parentDirectory
        self.xcworkspace = xcworkspace
    }
}

public struct MockProjectProvider: ProjectProviding {
    public let sourceDirectory: AbsolutePath
    public let xcodeProjPath: AbsolutePath
    public let xcodeProj: XcodeProj
    public var pbxProj: PBXProj {
        xcodeProj.pbxproj
    }

    public init(
        sourceDirectory: String = "/tmp",
        projectName: String = "TestProject",
        configurationList: XCConfigurationList? = nil,
        pbxProj: PBXProj = PBXProj()
    ) {
        let configurationList = configurationList ?? .mock(proj: pbxProj)
        self.sourceDirectory = try! AbsolutePath.resolvePath(sourceDirectory)
        xcodeProjPath = self.sourceDirectory.appending(component: "TestProject.xcodproj")
        // minimal project setup
        let pbxProject = PBXProject.mock(
            name: projectName, buildConfigurationList: configurationList, pbxProj: pbxProj
        )
        pbxProj.add(object: pbxProject)
        pbxProj.add(object: configurationList)
        pbxProj.rootObject = pbxProject

        xcodeProj = XcodeProj(workspace: XCWorkspace(), pbxproj: pbxProj)
    }

    public func pbxProject() throws -> PBXProject {
        return xcodeProj.pbxproj.projects.first!
    }
}

extension MockProjectProvider {
    public static func makeBasicProjectProvider(
        projectName: String = "TestProject",
        sourceDirectory: String = "/tmp/\(UUID().uuidString)"
    ) -> MockProjectProvider {
        return MockProjectProvider(
            sourceDirectory: sourceDirectory,
            projectName: projectName
        )
    }

    public func addTargets(_ targets: [PBXNativeTarget]) throws {
        let project = try pbxProject()
        project.targets.append(contentsOf: targets)
    }
}

extension ProjectMapper {
    public func createMappedProject(
        projectName: String = "TestProject",
        targets: [PBXNativeTarget] = []
    ) async throws -> Project {
        let provider = MockProjectProvider.makeBasicProjectProvider(projectName: projectName)
        try provider.addTargets(targets)

        let mapper = ProjectMapper(projectProvider: provider)
        return try await mapper.mapProject()
    }

    public func createMappedGraph(
        graphType: GraphType,
        projectProviders: [AbsolutePath: MockProjectProvider]
    ) async throws -> XcodeGraph.Graph {
        let mapper = GraphMapper(graphType: graphType) { path in
            guard let provider = projectProviders[path] else {
                Issue.record("Unexpected project path requested: \(path)")
                throw MappingError.noProjectsFound(path: path.pathString)
            }
            return provider
        }

        return try await mapper.xcodeGraph()
    }
}
