import Foundation
import Testing
import TestSupport
import XcodeProjToGraph

@Suite
struct LipoToolTests {
    @Test("Parses multiple architectures correctly from Lipo output")
    func testArchs_ValidOutput() async throws {
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

    @Test("Handles a single architecture output")
    func testArchs_SingleArchitecture() async throws {
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

    @Test("Throws an error when Lipo returns a non-zero exit code")
    func testArchs_NonZeroExitCode() async throws {
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

    @Test("Handles empty output gracefully")
    func testArchs_EmptyOutput() async throws {
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

    @Test("Throws an error if the Lipo executable is not found")
    func testArchs_ExecutableNotFound() async throws {
        // Arrange
        let nonExistentExecutable = "/nonexistent/path/to/lipo"

        // Act & Assert
        await #expect(throws: ProcessRunnerError.executableNotFound(nonExistentExecutable)) {
            try await LipoTool.archs(paths: ["/mock/path/to/file"], executablePath: nonExistentExecutable)
        }
    }
}
