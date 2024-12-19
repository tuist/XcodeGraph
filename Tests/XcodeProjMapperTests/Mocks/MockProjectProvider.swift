
import Foundation
import Path
import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeProjMapper

/// A mock project provider that sets up a minimal, in-memory Xcode project for testing.
struct MockProjectProvider: ProjectProviding {
    var sourceDirectory: AbsolutePath
    var xcodeProjPath: AbsolutePath
    var xcodeProj: XcodeProj

    var pbxProj: PBXProj {
        xcodeProj.pbxproj
    }

    init(
        sourceDirectory: String = "/tmp",
        projectName: String = "TestProject",
        configurationList: XCConfigurationList? = nil,
        pbxProj: PBXProj = PBXProj()
    ) {
        let finalConfigList = configurationList ?? .test()
        pbxProj.add(object: finalConfigList)

        self.sourceDirectory = try! AbsolutePath(validating: sourceDirectory)
        xcodeProjPath = self.sourceDirectory.appending(component: "TestProject.xcodproj")

        // Minimal project setup:
        let mainGroup = PBXGroup.test(
            children: [],
            sourceTree: .group,
            name: "MainGroup",
            path: "/tmp/TestProject"
        ).add(to: pbxProj)

        let projectRef = PBXFileReference
            .test(name: "App", path: "App.xcodeproj")
            .add(to: pbxProj)
        mainGroup.children.append(projectRef)

        let projects = [
            ["B900DB68213936CC004AEC3E": projectRef],
        ]

        let pbxProject = PBXProject.test(
            name: projectName,
            buildConfigurationList: finalConfigList,
            mainGroup: mainGroup,
            projects: projects
        ).add(to: pbxProj)

        pbxProject.mainGroup = mainGroup
        pbxProj.add(object: pbxProject)
        pbxProj.rootObject = pbxProject

        xcodeProj = XcodeProj(workspace: XCWorkspace(), pbxproj: pbxProj)
    }

    func pbxProject() throws -> PBXProject {
        try #require(xcodeProj.pbxproj.projects.first)
    }

    /// Creates a basic mock project provider with a unique temporary directory.
    static func makeBasicProjectProvider(
        projectName: String = "TestProject",
        sourceDirectory: String = "/tmp/\(UUID().uuidString)"
    ) -> MockProjectProvider {
        MockProjectProvider(
            sourceDirectory: sourceDirectory,
            projectName: projectName
        )
    }

    /// Adds the provided targets to the project's PBXProject.
    func addTargets(_ targets: [PBXNativeTarget]) throws {
        let project = try pbxProject()
        project.targets.append(contentsOf: targets)
    }
}

// MARK: - Extending PBXProjectMapper for Testing Utilities
