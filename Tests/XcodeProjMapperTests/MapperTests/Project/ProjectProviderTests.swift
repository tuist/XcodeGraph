import Testing
import XcodeGraph
import XcodeProj
import Path
@testable import XcodeProjMapper

@Suite
struct ProjectProviderTests {
    @Test("Returns pbxProject successfully when project exists")
    func testPBXProjectSuccess() throws {
        // Create a dummy PBXProject
        let proj = PBXProj()
        let pbxProject = PBXProject.test(
            name: "TestProject",
            buildConfigurationList: .test(),
            mainGroup: .test(),
            projects: []
        )

        proj.add(object: pbxProject)
        proj.rootObject = pbxProject

        let xcodeProj = XcodeProj(
            workspace: XCWorkspace(data: XCWorkspaceData(children: [])),
            pbxproj: proj
        )

        let provider = ProjectProvider(
            xcodeProjPath: try AbsolutePath(validating: "/tmp/TestProject.xcodeproj"),
            xcodeProj: xcodeProj
        )

        let project = try provider.pbxProject()
        #expect(project.name == "TestProject")
    }

    @Test("Throws noProjectsFound error when no projects are present")
    func testNoProjectsFoundError() throws {
        let proj = PBXProj()
        // No PBXProject added to 'proj', so this should trigger the error
        let xcodeProj = XcodeProj(
            workspace: XCWorkspace(data: XCWorkspaceData(children: [])),
            pbxproj: proj
        )

        let provider = ProjectProvider(
            xcodeProjPath: try AbsolutePath(validating: "/tmp/EmptyProject.xcodeproj"),
            xcodeProj: xcodeProj
        )

        #expect(throws: ProjectProvidingError.noProjectsFound(path: "/tmp/EmptyProject.xcodeproj")) {
            _ = try provider.pbxProject()
        }

        #expect {
            _ = try provider.pbxProject()
        } throws: { error in
            return error.localizedDescription == "No `PBXProject` was found in the `.xcodeproj` at: /tmp/EmptyProject.xcodeproj."
        }

    }

    @Test("Verifies sourceDirectory is parent of xcodeProjPath")
    func testSourceDirectoryComputation() throws {
        let proj = PBXProj()
        let pbxProject = PBXProject.test(
            name: "TestProject",
            buildConfigurationList: .test(),
            mainGroup: .test(),
            projects: []
        )

        proj.add(object: pbxProject)
        proj.rootObject = pbxProject

        let xcodeProj = XcodeProj(
            workspace: XCWorkspace(data: XCWorkspaceData(children: [])),
            pbxproj: proj
        )

        let provider = ProjectProvider(
            xcodeProjPath: try AbsolutePath(validating: "/tmp/Projects/TestProject.xcodeproj"),
            xcodeProj: xcodeProj
        )

        #expect(provider.sourceDirectory.pathString == "/tmp/Projects")
    }
}
