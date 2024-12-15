import Foundation

public final class ProcessRunner {
    /// Runs the given executable asynchronously and processes its result using the associated parser.
    ///
    /// - Parameters:
    ///   - executable: An `Executable` that defines the command, arguments, and output parser.
    ///   - environment: An optional dictionary of environment variables for the process.
    ///   - workingDirectory: An optional path for the process's working directory.
    ///   - throwOnNonZeroExit: If `true`, throws an error for non-zero exit codes. Defaults to `true`.
    /// - Returns: The structured output parsed from the process's result.
    /// - Throws:
    ///   - `ProcessRunnerError` for issues like non-zero exit codes, invalid UTF-8, or failure to run.
    @discardableResult
    public static func run<T: Sendable>(
        executable: Executable<T>,
        environment: [String: String]? = nil,
        workingDirectory: String? = nil,
        throwOnNonZeroExit: Bool = true,
        fileManager: FileManager = FileManager.default
    ) async throws -> T {
        let execPath = executable.path

        guard fileManager.isExecutableFile(atPath: execPath) else {
            throw ProcessRunnerError.executableNotFound(execPath)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: execPath)
            process.arguments = executable.arguments
            process.environment = environment ?? ProcessInfo.processInfo.environment
            if let wd = workingDirectory {
                process.currentDirectoryURL = URL(fileURLWithPath: wd)
            }

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            process.terminationHandler = { process in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                guard
                    let stdoutString = String(data: stdoutData, encoding: .utf8),
                    let stderrString = String(data: stderrData, encoding: .utf8)
                else {
                    continuation.resume(throwing: ProcessRunnerError.invalidUTF8InOutput)
                    return
                }

                let exitCode = process.terminationStatus
                let result = ProcessResult(exitCode: exitCode, stdout: stdoutString, stderr: stderrString)

                if throwOnNonZeroExit && !result.succeeded {
                    continuation.resume(throwing: ProcessRunnerError.nonZeroExitCode(exitCode, result.stderr))
                    return
                }

                do {
                    let output = try executable.parser(result)
                    continuation.resume(returning: output)
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: ProcessRunnerError.failedToRunProcess(error.localizedDescription))
            }
        }
    }
}
