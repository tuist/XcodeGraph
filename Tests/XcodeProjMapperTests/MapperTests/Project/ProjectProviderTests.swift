import Path
import Testing
import XcodeGraph
import XcodeProj
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

        let project = try xcodeProj.mainPBXProject()
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

        #expect {
            _ = try xcodeProj.mainPBXProject()
        } throws: { error in
            return error.localizedDescription == "No `PBXProject` was found in the `.xcodeproj`"
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

        let sourceDirectory = xcodeProj.srcPathString
        #expect(sourceDirectory == "/tmp/Projects")
    }
}
