import Foundation
import Testing
import TestSupport
import XcodeProjToGraph

@Suite
struct LipoToolTests {
    /// Test that `LipoTool.archs` successfully parses valid output.
    @Test func testArchs_ValidOutput() async throws {
        // Arrange
        let mockExecutablePath = try MockFileCreator.createTemporaryExecutable(
            withContent: """
            #!/bin/sh
            echo "arm64 x86_64"
            exit 0
            """
        )

        // Act
        let result = try await LipoTool.archs(
            paths: ["/mock/path/to/file"], executablePath: mockExecutablePath
        )

        // Assert
        #expect(result.architectures == [.arm64, .x8664])
    }

    /// Test that `LipoTool.archs` handles a single architecture output.
    @Test func testArchs_SingleArchitecture() async throws {
        // Arrange
        let mockExecutablePath = try MockFileCreator.createTemporaryExecutable(
            withContent: """
            #!/bin/sh
            echo "arm64"
            exit 0
            """
        )

        // Act
        let result = try await LipoTool.archs(
            paths: ["/mock/path/to/file"], executablePath: mockExecutablePath
        )

        // Assert
        #expect(result.architectures == [.arm64])
    }

    /// Test that `LipoTool.archs` throws an error on non-zero exit code.
    @Test func testArchs_NonZeroExitCode() async throws {
        // Arrange
        let mockExecutablePath = try MockFileCreator.createTemporaryExecutable(
            withContent: """
            #!/bin/sh
            echo "Error: invalid usage"
            exit 1
            """
        )

        // Act & Assert
        await #expect(throws: ProcessRunnerError.failedToRunProcess("Lipo returned non-zero exit code.")) {
            try await LipoTool.archs(paths: ["/mock/path/to/file"], executablePath: mockExecutablePath)
        }
    }

    /// Test that `LipoTool.archs` handles empty output gracefully.
    @Test func testArchs_EmptyOutput() async throws {
        // Arrange
        let mockExecutablePath = try MockFileCreator.createTemporaryExecutable(
            withContent: """
            #!/bin/sh
            echo ""
            exit 0
            """
        )

        // Act
        let result = try await LipoTool.archs(
            paths: ["/mock/path/to/file"], executablePath: mockExecutablePath
        )

        // Assert
        #expect(result.architectures.isEmpty == true)
    }

    /// Test that `LipoTool.archs` throws an error if the executable does not exist.
    @Test func testArchs_ExecutableNotFound() async throws {
        // Arrange
        let nonExistentExecutable = "/nonexistent/path/to/lipo"

        // Act & Assert
        await #expect(throws: ProcessRunnerError.executableNotFound(nonExistentExecutable)) {
            try await LipoTool.archs(paths: ["/mock/path/to/file"], executablePath: nonExistentExecutable)
        }
    }
}
