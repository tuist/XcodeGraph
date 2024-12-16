import Foundation
import Path
import Testing
import XcodeGraph
import XcodeProj

@testable import XcodeProjToGraph

@Suite
struct ProjectParserTests {
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
    func testParseWorkspace() async throws {
        // Arrange
        let mockDirectory = try createMockDirectory(withContents: ["MyWorkspace.xcworkspace"])
        let workspacePath = mockDirectory.appending(component: "MyWorkspace.xcworkspace")

        // Act
        let graph = try await ProjectParser.parse(atPath: workspacePath.pathString)

        // Assert
        #expect(graph.name == "MyWorkspace")
    }

    @Test("Parses a directory containing a valid .xcodeproj file")
    func testParseXcodeProject() async throws {
        // Arrange
        let mockDirectory = try createMockDirectory(withContents: ["MyProject.xcodeproj"])
        let projectPath = mockDirectory.appending(component: "MyProject.xcodeproj")

        // Act
        let graph = try await ProjectParser.parse(atPath: projectPath.pathString)

        // Assert
        #expect(graph.name == "Workspace")
    }

    @Test("Parses a directory with both .xcworkspace and .xcodeproj, preferring the workspace")
    func testParseDirectoryWithWorkspaceAndProject() async throws {
        // Arrange
        let mockDirectory = try createMockDirectory(withContents: [
            "MyWorkspace.xcworkspace", "MyProject.xcodeproj",
        ])

        // Act
        let graph = try await ProjectParser.parse(atPath: mockDirectory.pathString)

        // Assert
        #expect(graph.name == "MyWorkspace")
    }

    @Test("Throws an error when no valid project files are found")
    func testParseDirectoryNoProjects() async throws {
        // Arrange
        let mockDirectory = try createMockDirectory(withContents: ["ReadMe.md", "file.txt"])

        // Act & Assert
        await #expect(throws: MappingError.noProjectsFound(path: mockDirectory.pathString)) {
            try await ProjectParser.parse(atPath: mockDirectory.pathString)
        }
    }

    @Test("Throws an error for a non-existent directory path")
    func testParseNonExistentPath() async throws {
        // Act & Assert
        await #expect(throws: MappingError.pathNotFound(path: "/non/existent/path")) {
            try await ProjectParser.parse(atPath: "/non/existent/path")
        }
    }

    @Test("Parses a directory with only an .xcodeproj file")
    func testParseDirectoryOnlyXcodeProj() async throws {
        // Arrange
        let mockDirectory = try createMockDirectory(withContents: ["MyProject.xcodeproj"])

        // Act
        let graph = try await ProjectParser.parse(atPath: mockDirectory.pathString)

        // Assert
        #expect(graph.name == "Workspace")
    }
}
