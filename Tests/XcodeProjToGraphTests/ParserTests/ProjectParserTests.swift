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

    /// Test parsing a valid `.xcworkspace` file
    @Test func testParseWorkspace() async throws {
        // Arrange
        let mockDirectory = try createMockDirectory(withContents: ["MyWorkspace.xcworkspace"])
        let workspacePath = mockDirectory.appending(component: "MyWorkspace.xcworkspace")

        // Act
        let graph = try await ProjectParser.parse(atPath: workspacePath.pathString)

        // Assert
        #expect(graph.name == "MyWorkspace")
    }

    /// Test parsing a valid `.xcodeproj` file
    @Test func testParseXcodeProject() async throws {
        // Arrange
        let mockDirectory = try createMockDirectory(withContents: ["MyProject.xcodeproj"])
        let projectPath = mockDirectory.appending(component: "MyProject.xcodeproj")

        // Act
        let graph = try await ProjectParser.parse(atPath: projectPath.pathString)

        // Assert
        #expect(graph.name == "Workspace")
    }

    /// Test parsing when directory contains both `.xcworkspace` and `.xcodeproj`
    @Test func testParseDirectoryWithWorkspaceAndProject() async throws {
        // Arrange
        let mockDirectory = try createMockDirectory(withContents: [
            "MyWorkspace.xcworkspace", "MyProject.xcodeproj",
        ])

        // Act
        let graph = try await ProjectParser.parse(atPath: mockDirectory.pathString)

        #expect(graph.name == "MyWorkspace")
    }

    /// Test parsing when the directory contains no valid project files
    @Test func testParseDirectoryNoProjects() async throws {
        // Arrange
        let mockDirectory = try createMockDirectory(withContents: ["ReadMe.md", "file.txt"])

        // Act & Assert
        await #expect(throws: MappingError.noProjectsFound) {
            try await ProjectParser.parse(atPath: mockDirectory.pathString)
        }
    }

    /// Test handling a non-existent path
    @Test func testParseNonExistentPath() async throws {
        // Act & Assert
        await #expect(throws: MappingError.pathNotFound(path: "/non/existent/path")) {
            try await ProjectParser.parse(atPath: "/non/existent/path")
        }
    }

    /// Test parsing when only `.xcodeproj` exists in the directory
    @Test func testParseDirectoryOnlyXcodeProj() async throws {
        // Arrange
        let mockDirectory = try createMockDirectory(withContents: ["MyProject.xcodeproj"])

        // Act
        let graph = try await ProjectParser.parse(atPath: mockDirectory.pathString)

        // Assert
        #expect(graph.name == "Workspace")
    }
}
