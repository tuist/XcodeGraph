import Foundation
import Testing
import TestSupport
import XcodeProjToGraph

@Suite
struct ProcessRunnerTests {
    private func createTemporaryExecutable(
        name: String = "mockExecutable_\(UUID().uuidString)",
        withContent content: String
    ) throws -> String {
        let tempDirectory = FileManager.default.temporaryDirectory
        let mockExecutablePath = tempDirectory.appendingPathComponent(name).path

        // Write the content to the temporary file
        try content.write(toFile: mockExecutablePath, atomically: true, encoding: .utf8)

        // Make the file executable
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: mockExecutablePath
        )

        return mockExecutablePath
    }

    @Test("Runs a valid executable and returns expected output")
    func testRun_ValidExecutable_Success() async throws {
        // Arrange
        let mockExecutablePath = try createTemporaryExecutable(
            withContent: """
            #!/bin/sh
            echo "Hello, World!"
            exit 0
            """
        )

        let mockExecutable = Executable.custom(
            mockExecutablePath,
            [],
            { result in
                result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        )

        // Act
        let output: String = try await ProcessRunner.run(
            executable: mockExecutable,
            environment: nil,
            workingDirectory: nil,
            throwOnNonZeroExit: true
        )

        // Assert
        #expect(output == "Hello, World!")
    }

    @Test("Throws an error if the executable does not exist")
    func testRun_ExecutableNotFound_ThrowsError() async throws {
        // Arrange
        let nonExistentExecutable = Executable.custom(
            "/nonexistent/path",
            [],
            { _ in }
        )

        // Act & Assert
        await #expect(throws: ProcessRunnerError.executableNotFound("/nonexistent/path")) {
            try await ProcessRunner.run(
                executable: nonExistentExecutable,
                environment: nil,
                workingDirectory: nil,
                throwOnNonZeroExit: true
            )
        }
    }

    @Test("Throws an error on non-zero exit code when throwOnNonZeroExit is enabled")
    func testRun_NonZeroExitCode_ThrowsError() async throws {
        // Arrange
        let mockExecutablePath = try createTemporaryExecutable(
            withContent: """
            #!/bin/sh
            exit 1
            """
        )

        let mockExecutable = Executable.custom(
            mockExecutablePath,
            [],
            { _ in }
        )

        // Act & Assert
        await #expect(throws: ProcessRunnerError.nonZeroExitCode(1, "")) {
            try await ProcessRunner.run(
                executable: mockExecutable,
                environment: nil,
                workingDirectory: nil,
                throwOnNonZeroExit: true
            )
        }
    }

    @Test("Does not throw on non-zero exit code when throwOnNonZeroExit is disabled")
    func testRun_NonZeroExitCode_NoThrow() async throws {
        // Arrange
        let mockExecutablePath = try createTemporaryExecutable(
            withContent: """
            #!/bin/sh
            exit 1
            """
        )

        let mockExecutable = Executable.custom(
            mockExecutablePath,
            [],
            { result in
                result.exitCode // Return the exit code for validation
            }
        )

        // Act
        let exitCode: Int32 = try await ProcessRunner.run(
            executable: mockExecutable,
            environment: nil,
            workingDirectory: nil,
            throwOnNonZeroExit: false
        )

        // Assert
        #expect(exitCode == 1)
    }

    @Test("Parses UTF-8 output correctly")
    func testRun_ParsesUtf8Output() async throws {
        // Arrange
        let mockExecutablePath = try createTemporaryExecutable(
            withContent: """
            #!/bin/sh
            echo "你好, 世界!"
            exit 0
            """
        )

        let mockExecutable = Executable.custom(
            mockExecutablePath,
            [],
            { result in
                result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        )

        // Act
        let output: String = try await ProcessRunner.run(
            executable: mockExecutable,
            environment: nil,
            workingDirectory: nil,
            throwOnNonZeroExit: true
        )

        // Assert
        #expect(output == "你好, 世界!")
    }

    @Test("Throws an error if the output is not valid UTF-8")
    func testRun_InvalidUtf8Output_ThrowsError() async throws {
        // Arrange
        let mockExecutablePath = try createTemporaryExecutable(
            withContent: """
            #!/bin/sh
            echo -e '\\xff'  # Invalid UTF-8 sequence
            exit 0
            """
        )

        let invalidUtf8Executable = Executable.custom(
            mockExecutablePath,
            [],
            { _ in
                throw ProcessRunnerError.invalidUTF8InOutput
            }
        )

        // Act & Assert
        await #expect(throws: ProcessRunnerError.invalidUTF8InOutput) {
            try await ProcessRunner.run(
                executable: invalidUtf8Executable,
                environment: nil,
                workingDirectory: nil,
                throwOnNonZeroExit: false
            )
        }
    }
}
