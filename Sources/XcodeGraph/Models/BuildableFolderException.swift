import Path

/// Represents exceptions for a buildable folder, such as files to exclude or specific compiler flags to apply.
public struct BuildableFolderException: Sendable, Codable, Equatable, Hashable {
    /// A list of absolute paths to files excluded from the buildable folder.
    public var exclued: [AbsolutePath]

    /// A dictionary mapping files (referenced by their absolute path) to the compiler flags to apply.
    public var compilerFlags: [AbsolutePath: String]

    /// Creates a new exception for a buildable folder.
    /// - Parameters:
    ///   - exclued: An array of absolute paths to files that should be excluded from the buildable folder.
    ///   - compilerFlags: A dictionary mapping absolute file paths to specific compiler flags to apply to those files.
    public init(exclued: [AbsolutePath], compilerFlags: [AbsolutePath: String]) {
        self.exclued = exclued
        self.compilerFlags = compilerFlags
    }
}
