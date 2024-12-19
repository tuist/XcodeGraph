import Foundation
import Path
import PathKit
import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeProjMapper

@Suite
struct XCWorkspaceMapperTests {
    @Test("Maps workspace without any projects or schemes")
    func testMap_NoProjectsOrSchemes() throws {
        let workspacePath = try AbsolutePath(validating: "/tmp/MyWorkspace.xcworkspace")
        let xcworkspace: XCWorkspace = .test(files: ["ReadMe.md"])

        let provider = MockWorkspaceProvider(
            xcWorkspacePath: workspacePath,
            xcworkspace: xcworkspace
        )
        let mapper = XCWorkspaceMapper()

        let workspace = try mapper.map(workspaceProvider: provider)

        #expect(workspace.name == "MyWorkspace")
        #expect(workspace.projects.isEmpty == true)
        #expect(workspace.schemes.isEmpty == true)
    }

    @Test("Maps workspace with multiple projects")
    func testMap_MultipleProjects() throws {
        let workspacePath = try AbsolutePath(validating: "/tmp/MyWorkspace.xcworkspace")
        let workspaceDir = workspacePath.parentDirectory
        let xcworkspace: XCWorkspace = .test(withElements: [
            .test(relativePath: "ProjectA.xcodeproj"),
            .group(XCWorkspaceDataGroup(
                location: .group("NestedGroup"),
                name: "NestedGroup",
                children: [
                    .test(relativePath: "ProjectB.xcodeproj"),
                    .test(relativePath: "Notes.txt"),
                ]
            )),
        ])

        let provider = MockWorkspaceProvider(
            xcWorkspacePath: workspacePath,
            xcworkspace: xcworkspace
        )
        let mapper = XCWorkspaceMapper()

        let workspace = try mapper.map(workspaceProvider: provider)

        #expect(workspace.name == "MyWorkspace")
        #expect(workspace.projects.count == 2)
        #expect(workspace.projects.contains(workspaceDir.appending(component: "ProjectA.xcodeproj")) == true)
        #expect(workspace.projects.contains(workspaceDir.appending(components: ["NestedGroup", "ProjectB.xcodeproj"])) == true)
        #expect(workspace.schemes.isEmpty == true)
    }

    @Test("Maps workspace with shared schemes")
    func testMap_WithSchemes() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
        let path = tempDirectory.appendingPathComponent("MyWorkspace.xcworkspace")
        let workspacePath = try AbsolutePath(validating: path.path)

        // Create a mock `.xcscheme` file in `xcshareddata/xcschemes`
        let sharedDataDir = workspacePath.pathString + "/xcshareddata/xcschemes"
        try FileManager.default.createDirectory(atPath: sharedDataDir, withIntermediateDirectories: true)
        let schemeFile = sharedDataDir + "/MyScheme.xcscheme"
        try "dummy scheme content".write(toFile: schemeFile, atomically: true, encoding: .utf8)

        let xcworkspace: XCWorkspace = .test(withElements: [.test(relativePath: "App.xcodeproj")])
        let provider = MockWorkspaceProvider(xcWorkspacePath: workspacePath, xcworkspace: xcworkspace)
        let mapper = XCWorkspaceMapper()

        do {
            _ = try mapper.map(workspaceProvider: provider)
        } catch {
            #expect(error.localizedDescription == "The operation couldn’t be completed. (NSXMLParserErrorDomain error 4.)")
        }
    }

    @Test("No schemes directory results in no schemes mapped")
    func testMap_NoSchemesDirectory() throws {
        let workspacePath = try AbsolutePath(validating: "/tmp/MyWorkspace.xcworkspace")

        let xcworkspace = XCWorkspace.test(withElements: [
            .test(relativePath: "App.xcodeproj"),
        ])

        let provider = MockWorkspaceProvider(
            xcWorkspacePath: workspacePath,
            xcworkspace: xcworkspace
        )
        let mapper = XCWorkspaceMapper()

        let workspace = try mapper.map(workspaceProvider: provider)
        #expect(workspace.schemes.isEmpty == true)
    }

    @Test("Workspace name is derived from the .xcworkspace file name")
    func testMap_NameDerivation() throws {
        let workspacePath = try AbsolutePath(validating: "/tmp/AnotherWorkspace.xcworkspace")
        let xcworkspace = XCWorkspace.test(withElements: [])
        let provider = MockWorkspaceProvider(xcWorkspacePath: workspacePath, xcworkspace: xcworkspace)
        let mapper = XCWorkspaceMapper()

        let workspace = try mapper.map(workspaceProvider: provider)
        #expect(workspace.name == "AnotherWorkspace")
    }

    @Test("Resolves absolute path in XCWorkspaceDataFileRef")
    func testMap_AbsolutePath() throws {
        let workspacePath = try AbsolutePath(validating: "/tmp/AbsWorkspace.xcworkspace")
        let elements: [XCWorkspaceDataElement] = [
            .file(XCWorkspaceDataFileRef(location: .absolute("/Users/SomeUser/ProjectC.xcodeproj"))),
        ]

        let xcworkspace = XCWorkspace(data: XCWorkspaceData(children: elements))
        let provider = MockWorkspaceProvider(xcWorkspacePath: workspacePath, xcworkspace: xcworkspace)
        let mapper = XCWorkspaceMapper()

        let workspace = try mapper.map(workspaceProvider: provider)
        #expect(workspace.projects.isEmpty == false)
    }

    @Test("Resolves container path in XCWorkspaceDataFileRef")
    func testMap_ContainerPath() throws {
        let workspacePath = try AbsolutePath(validating: "/tmp/ContainerWorkspace.xcworkspace")
        let elements: [XCWorkspaceDataElement] = [
            .file(XCWorkspaceDataFileRef(location: .container("Nested/ProjectD.xcodeproj"))),
        ]

        let xcworkspace = XCWorkspace(data: XCWorkspaceData(children: elements))
        let provider = MockWorkspaceProvider(xcWorkspacePath: workspacePath, xcworkspace: xcworkspace)
        let mapper = XCWorkspaceMapper()

        // container paths are relative to workspacePath parent directory
        let workspace = try mapper.map(workspaceProvider: provider)
        #expect(workspace.projects.isEmpty == false)
    }

    @Test("Resolves developer path in XCWorkspaceDataFileRef")
    func testMap_DeveloperPath() throws {
        let workspacePath = try AbsolutePath(validating: "/tmp/DevWorkspace.xcworkspace")
        let elements: [XCWorkspaceDataElement] = [
            .file(XCWorkspaceDataFileRef(location: .developer("Platforms/iPhoneOS.platform/Developer/ProjectE.xcodeproj"))),
        ]

        let xcworkspace = XCWorkspace(data: XCWorkspaceData(children: elements))
        let provider = MockWorkspaceProvider(xcWorkspacePath: workspacePath, xcworkspace: xcworkspace)
        let mapper = XCWorkspaceMapper()

        let workspace = try mapper.map(workspaceProvider: provider)
        #expect(workspace.projects.isEmpty == false)
    }

    @Test("Resolves group path in XCWorkspaceDataFileRef")
    func testMap_GroupPath() throws {
        let workspacePath = try AbsolutePath(validating: "/tmp/GroupWorkspace.xcworkspace")
        let elements: [XCWorkspaceDataElement] = [
            .group(XCWorkspaceDataGroup(location: .group("MyGroup"), name: "MyGroup", children: [
                .file(XCWorkspaceDataFileRef(location: .group("Subfolder/ProjectF.xcodeproj"))),
            ])),
        ]

        let xcworkspace = XCWorkspace(data: XCWorkspaceData(children: elements))
        let provider = MockWorkspaceProvider(xcWorkspacePath: workspacePath, xcworkspace: xcworkspace)
        let mapper = XCWorkspaceMapper()

        let workspace = try mapper.map(workspaceProvider: provider)
        #expect(workspace.projects.isEmpty == false)
    }

    @Test("Resolves current path in XCWorkspaceDataFileRef")
    func testMap_CurrentPath() throws {
        let workspacePath = try AbsolutePath(validating: "/tmp/CurrentWorkspace.xcworkspace")
        let elements: [XCWorkspaceDataElement] = [
            .file(XCWorkspaceDataFileRef(location: .current("RelativePath/ProjectG.xcodeproj"))),
        ]

        let xcworkspace = XCWorkspace(data: XCWorkspaceData(children: elements))
        let provider = MockWorkspaceProvider(xcWorkspacePath: workspacePath, xcworkspace: xcworkspace)
        let mapper = XCWorkspaceMapper()

        let workspace = try mapper.map(workspaceProvider: provider)
        #expect(workspace.projects.isEmpty == false)
    }

    @Test("Resolves other path in XCWorkspaceDataFileRef")
    func testMap_OtherPath() throws {
        let workspacePath = try AbsolutePath(validating: "/tmp/OtherWorkspace.xcworkspace")
        let elements: [XCWorkspaceDataElement] = [
            .file(XCWorkspaceDataFileRef(location: .other("customscheme", "Path/ProjectH.xcodeproj"))),
        ]

        let xcworkspace = XCWorkspace(data: XCWorkspaceData(children: elements))
        let provider = MockWorkspaceProvider(xcWorkspacePath: workspacePath, xcworkspace: xcworkspace)
        let mapper = XCWorkspaceMapper()

        let workspace = try mapper.map(workspaceProvider: provider)
        #expect(workspace.projects.isEmpty == false)
    }
}
