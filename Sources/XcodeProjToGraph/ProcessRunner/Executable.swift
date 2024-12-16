import Foundation

// MARK: - Executable

/// Represents an executable command with its arguments, executable path, and a parser for the output.
///
/// Used to define commands like `lipo` or custom executables, encapsulating the logic
/// for arguments, path, and output processing.
public enum Executable<Output: Sendable>: Sendable {
    /// A `lipo` command, used for managing universal binaries.
    ///
    /// - Parameters:
    ///   - arguments: The arguments to pass to `lipo`.
    ///   - parser: A closure to parse the `ProcessResult` into an `Output`.
    ///   - executablePath: The path to the `lipo` binary (default: `/usr/bin/lipo`).
    case lipo(LipoArguments, @Sendable (ProcessResult) throws -> Output, executablePath: String = "/usr/bin/lipo")

    /// A custom executable command.
    ///
    /// - Parameters:
    ///   - executablePath: The path to the custom executable.
    ///   - arguments: The arguments to pass to the executable.
    ///   - parser: A closure to parse the `ProcessResult` into an `Output`.
    case custom(String, [String], @Sendable (ProcessResult) throws -> Output)

    /// The path to the executable.
    public var path: String {
        switch self {
        case let .lipo(_, _, path):
            return path
        case let .custom(executablePath, _, _):
            return executablePath
        }
    }

    /// The arguments to pass to the executable.
    public var arguments: [String] {
        switch self {
        case let .lipo(lipoArgs, _, _):
            return lipoArgs.toArguments()
        case let .custom(_, args, _):
            return args
        }
    }

    /// A parser to convert the `ProcessResult` into the desired `Output` type.
    public var parser: (ProcessResult) throws -> Output {
        switch self {
        case let .lipo(_, parser, _):
            return parser
        case let .custom(_, _, parser):
            return parser
        }
    }
}
