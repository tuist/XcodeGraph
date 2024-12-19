import Foundation
import Path
import Testing
import XcodeGraph
import XcodeProj

@testable import XcodeProjMapper

@Suite
struct ProjectParserTests {
    let parser: ProjectParser

    init() {
        parser = ProjectParser()
    }

    private func createMockDirectory(withContents contents: [String]) throws -> AbsolutePath {
        let tempDirectory = FileManager.default.temporaryDirectory
        let mockDirectory = tempDirectory.appendingPathComponent("MockDirectory_\(UUID().uuidString)")
            .path
        try FileManager.default.createDirectory(
            atPath: mockDirectory, withIntermediateDirectories: true
        )

        for item in contents {
            let itemPath = mockDirectory + "/" + item
            if item.hasSuffix(".xcworkspace") || item.hasSuffix(".xcodeproj") {
                try FileManager.default.createDirectory(atPath: itemPath, withIntermediateDirectories: true)
            } else {
                FileManager.default.createFile(atPath: itemPath, contents: nil)
            }
        }

        return try AbsolutePath(validating: mockDirectory)
    }

    @Test("Parses a directory containing a valid .xcworkspace file")
    func testParseWorkspace() throws {
        // Arrange
        let mockDirectory = try createMockDirectory(withContents: ["MyWorkspace.xcworkspace"])
        let workspacePath = mockDirectory.appending(component: "MyWorkspace.xcworkspace")

        // Act
        let graph = try parser.parse(at: workspacePath.pathString)

        // Assert
        #expect(graph.name == "MyWorkspace")
    }

    @Test("Parses a directory containing a valid .xcodeproj file")
    func testParseXcodeProject() throws {
        // Arrange
        let mockDirectory = try createMockDirectory(withContents: ["MyProject.xcodeproj"])
        let projectPath = mockDirectory.appending(component: "MyProject.xcodeproj")

        // Act

        let type = try parser.determineProjectType(at: projectPath)

        // Assert
        #expect(type == ProjectType.xcodeProject(projectPath))
    }

    @Test("Parses a directory with both .xcworkspace and .xcodeproj, preferring the workspace")
    func testParseDirectoryWithWorkspaceAndProject() throws {
        // Arrange
        let mockDirectory = try createMockDirectory(withContents: [
            "MyWorkspace.xcworkspace", "MyProject.xcodeproj",
        ])

        // Act
        let graph = try parser.parse(at: mockDirectory.pathString)

        // Assert
        #expect(graph.name == "MyWorkspace")
    }

    @Test("Throws an error when no valid project files are found")
    func testParseDirectoryNoProjects() throws {
        // Arrange
        let mockDirectory = try createMockDirectory(withContents: ["ReadMe.md", "file.txt"])

        // Act & Assert
        #expect(throws: ProjectParserError.noProjectsFound(path: mockDirectory.pathString)) {
            try parser.parse(at: mockDirectory.pathString)
        }
    }

    @Test("Throws an error for a non-existent directory path")
    func testParseNonExistentPath() throws {
        // Act & Assert
        #expect(throws: ProjectParserError.pathNotFound(path: "/non/existent/path")) {
            try parser.parse(at: "/non/existent/path")
        }
    }

    @Test("Parses a directory with only an .xcodeproj file")
    func testParseDirectoryOnlyXcodeProj() throws {
        // Arrange
        let mockDirectory = try createMockDirectory(withContents: ["MyProject.xcodeproj"])
        // Act
        let type = try parser.determineProjectType(at: mockDirectory)

        // Assert
        #expect(type == ProjectType.xcodeProject(mockDirectory.appending(component: "MyProject.xcodeproj")))
    }
}
