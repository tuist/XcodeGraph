import Foundation

/// Represents the result of executing a process.
///
/// This struct encapsulates the process's exit code, standard output, and standard error streams,
/// and provides a convenience property to determine if the process succeeded.
public struct ProcessResult: Sendable, CustomStringConvertible {
    /// The exit code of the process.
    ///
    /// A value of `0` typically indicates success, while non-zero values represent errors.
    public let exitCode: Int32

    /// The standard output of the process as a `String`.
    public let stdout: String

    /// The standard error output of the process as a `String`.
    public let stderr: String

    /// Indicates whether the process exited successfully.
    ///
    /// - Returns: `true` if the exit code is `0`, otherwise `false`.
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
