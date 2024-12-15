import Foundation

/// Represents an executable command with its arguments, executable path, and a parser for the output.
///
/// This enum is used to define commands like `lipo` or custom executables, encapsulating the logic
/// for their arguments, path, and output processing.
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
    ///
    /// - Returns: A `String` representing the absolute path to the executable.
    public var path: String {
        switch self {
        case .lipo(_, _, let path):
            return path
        case .custom(let executablePath, _, _):
            return executablePath
        }
    }

    /// The arguments to pass to the executable.
    ///
    /// - Returns: An array of `String` arguments.
    public var arguments: [String] {
        switch self {
        case .lipo(let lipoArgs, _, _):
            return lipoArgs.toArguments()
        case .custom(_, let args, _):
            return args
        }
    }

    /// A parser to convert the `ProcessResult` into the desired `Output` type.
    ///
    /// - Returns: A closure that takes a `ProcessResult` and returns an `Output` value or throws an error.
    public var parser: (ProcessResult) throws -> Output {
        switch self {
        case .lipo(_, let parser, _):
            return parser
        case .custom(_, _, let parser):
            return parser
        }
    }
}
