import Foundation

/// A utility class for invoking `lipo` commands and parsing their results.
///
/// `LipoTool` provides a high-level interface for running `lipo -archs` on given paths
/// to determine which architectures a binary contains.
public final class LipoTool {
    /// Runs `lipo -archs` on the given paths and returns a `LipoArchsResult`.
    ///
    /// This method asynchronously executes `lipo -archs` using `ProcessRunner.run`,
    /// then parses the output into a `LipoArchsResult`. The result includes all architectures
    /// detected in the provided binary(ies).
    ///
    /// - Parameters:
    ///   - paths: An array of file paths to the binary files you want to inspect for architectures.
    ///             Typically, passing one path is common, but multiple paths can also be provided.
    ///   - executablePath: The path to the `lipo` executable. Defaults to `/usr/bin/lipo`.
    ///
    /// - Returns: A `LipoArchsResult` representing the architectures found.
    ///
    /// - Throws:
    ///   - `ProcessRunnerError` if there are issues running the `lipo` command or decoding its output.
    ///   - Any errors thrown by `parseLipoArchsResult` if the output is malformed.
    ///
    /// - Note: This method is `async` and may suspend. Ensure you're calling it from an asynchronous
    ///   context or within a `Task`.
    @discardableResult
    public static func archs(
        paths: [String],
        executablePath: String = "/usr/bin/lipo"
    ) async throws -> LipoArchsResult {
        let args = LipoArguments(operation: .archs, paths: paths)
        let executable = Executable.lipo(args, parseLipoArchsResult, executablePath: executablePath)
        return try await ProcessRunner.run(executable: executable, throwOnNonZeroExit: false)
    }
}
