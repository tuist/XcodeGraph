import Foundation

// MARK: - ProcessResult

/// Represents the result of executing a process, including exit code, stdout, and stderr.
public struct ProcessResult: Sendable, CustomStringConvertible {
    /// The exit code of the process. `0` typically indicates success.
    public let exitCode: Int32

    /// The standard output of the process as a `String`.
    public let stdout: String

    /// The standard error output of the process as a `String`.
    public let stderr: String

    /// Indicates whether the process exited successfully.
    public var succeeded: Bool {
        exitCode == 0
    }

    public var description: String {
        """
        Exit Code: \(exitCode)
        Stdout: \(stdout)
        Stderr: \(stderr)
        """
    }
}
