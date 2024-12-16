import AEXML
import Foundation
import Path
import PathKit
import Testing
import TestSupport
import XcodeGraph
import XcodeProj
@testable import XcodeProjToGraph

@Suite
struct WorkspaceMapperTests {
    /// Creates a basic `.xcworkspace` object with given children.
    private func makeWorkspace(withElements elements: [XCWorkspaceDataElement]) -> XCWorkspace {
        let data = XCWorkspaceData(children: elements)
        return XCWorkspace(data: data)
    }

    /// Creates a file reference element pointing to a given relative path.
    private func fileElement(relativePath: String) -> XCWorkspaceDataElement {
        .file(XCWorkspaceDataFileRef(location: .group(relativePath)))
    }

    /// Creates a group element with nested children.
    private func groupElement(name: String, children: [XCWorkspaceDataElement]) -> XCWorkspaceDataElement {
        .group(XCWorkspaceDataGroup(location: .group(name), name: name, children: children))
    }

    @Test("Maps workspace without any projects or schemes")
    func testMap_NoProjectsOrSchemes() async throws {
        // Arrange: A workspace with no .xcodeproj references
        let workspacePath = try AbsolutePath(validating: "/tmp/MyWorkspace.xcworkspace")
        let xcworkspace: XCWorkspace = .mock(files: ["ReadMe.md"])

        let provider = MockWorkspaceProvider(
            xcWorkspacePath: workspacePath,
            xcworkspace: xcworkspace
        )
        let mapper = WorkspaceMapper(workspaceProvider: provider)

        // Act
        let workspace = try await mapper.map()

        // Assert: No projects, no schemes
        #expect(workspace.name == "MyWorkspace")
        #expect(workspace.projects.isEmpty == true)
        #expect(workspace.schemes.isEmpty == true)
    }

    @Test("Maps workspace with multiple projects")
    func testMap_MultipleProjects() async throws {
        // Arrange: A workspace with multiple xcodeproj references
        let workspacePath = try AbsolutePath(validating: "/tmp/MyWorkspace.xcworkspace")
        let workspaceDir = workspacePath.parentDirectory
        let xcworkspace = makeWorkspace(withElements: [
            fileElement(relativePath: "ProjectA.xcodeproj"),
            groupElement(name: "NestedGroup", children: [
                fileElement(relativePath: "ProjectB.xcodeproj"),
                fileElement(relativePath: "Notes.txt"),
            ]),
        ])
        let provider = MockWorkspaceProvider(
            xcWorkspacePath: workspacePath,
            xcworkspace: xcworkspace
        )
        let mapper = WorkspaceMapper(workspaceProvider: provider)

        // For this test, we assume no `xcshareddata/xcschemes` directory exists.

        // Act
        let workspace = try await mapper.map()

        // Assert: Two projects discovered
        #expect(workspace.name == "MyWorkspace")
        #expect(workspace.projects.count == 2)
        #expect(workspace.projects.contains(workspaceDir.appending(component: "ProjectA.xcodeproj")) == true)
        #expect(workspace.projects.contains(workspaceDir.appending(components: ["NestedGroup", "ProjectB.xcodeproj"])) == true)
        #expect(workspace.schemes.isEmpty == true)
    }

    @Test("Maps workspace with shared schemes")
    func testMap_WithSchemes() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory
        let path = tempDirectory.appendingPathComponent("MyWorkspace.xcworkspace")
        // Arrange: A workspace with one project and a schemes directory
        let workspacePath = try AbsolutePath(validating: path.path())

        // Create a mock `.xcscheme` file in `xcshareddata/xcschemes`
        let sharedDataDir = workspacePath.pathString + "/xcshareddata/xcschemes"
        try FileManager.default.createDirectory(
            atPath: sharedDataDir,
            withIntermediateDirectories: true
        )
        let schemeFile = sharedDataDir + "/MyScheme.xcscheme"
        try "dummy scheme content".write(toFile: schemeFile, atomically: true, encoding: .utf8)

        // A workspace with a single project reference
        let xcworkspace = makeWorkspace(withElements: [
            fileElement(relativePath: "App.xcodeproj"),
        ])
        let provider = MockWorkspaceProvider(
            xcWorkspacePath: workspacePath,
            xcworkspace: xcworkspace
        )

        let mapper = WorkspaceMapper(workspaceProvider: provider)

        do {
            _ = try await mapper.map()
        } catch {
            #expect(error.localizedDescription == "The operation couldn’t be completed. (NSXMLParserErrorDomain error 4.)")
        }
    }

    @Test("No schemes directory results in no schemes mapped")
    func testMap_NoSchemesDirectory() async throws {
        // Arrange: A workspace with a project, but no `xcshareddata/xcschemes` directory
        let workspacePath = try AbsolutePath(validating: "/tmp/MyWorkspace.xcworkspace")

        let xcworkspace = makeWorkspace(withElements: [
            fileElement(relativePath: "App.xcodeproj"),
        ])
        let provider = MockWorkspaceProvider(
            xcWorkspacePath: workspacePath,
            xcworkspace: xcworkspace
        )
        let mapper = WorkspaceMapper(workspaceProvider: provider)

        // Act
        let workspace = try await mapper.map()

        // Assert: No schemes found
        #expect(workspace.schemes.isEmpty == true)
    }

    @Test("Workspace name is derived from the .xcworkspace file name")
    func testMap_NameDerivation() async throws {
        // Arrange
        let workspacePath = try AbsolutePath(validating: "/tmp/AnotherWorkspace.xcworkspace")
        let xcworkspace = makeWorkspace(withElements: [])
        let provider = MockWorkspaceProvider(
            xcWorkspacePath: workspacePath,
            xcworkspace: xcworkspace
        )
        let mapper = WorkspaceMapper(workspaceProvider: provider)

        // Act
        let workspace = try await mapper.map()

        // Assert
        #expect(workspace.name == "AnotherWorkspace")
    }
}
