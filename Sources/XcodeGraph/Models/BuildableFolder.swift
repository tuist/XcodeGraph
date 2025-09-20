import Path

/// A buildable folder maps to an PBXFileSystemSynchronizedRootGroup in Xcode projects.
/// Synchronized groups were introduced in Xcode 16 to reduce git conflicts by having a reference
/// to a folder whose content is "synchronized" by Xcode itself. Think of it as Xcode resolving
/// the globs.
public struct BuildableFolder: Sendable, Codable, Equatable, Hashable {
    /// The absolute path to the buildable folder.
    public var path: AbsolutePath

    /// Exceptions associated with this buildable folder, describing files to exclude or per-file build configuration overrides.
    public var exceptions: BuildableFolderExceptions

    /// A list of absolute paths resolved from this folder, allowing consumers to work with all files without extra I/O
    /// operations.
    public var resolvedPaths: [AbsolutePath]

    /// Creates a new `BuildableFolder` instance.
    /// - Parameters:
    ///   - path: The absolute path to the buildable folder.
    ///   - exceptions: The set of exceptions (such as excluded files or custom compiler flags) for the folder.
    ///   - resolvedPaths: The list of absolute file paths resolved from the folder, to avoid extra file system operations.
    public init(path: AbsolutePath, exceptions: BuildableFolderExceptions, resolvedPaths: [AbsolutePath]) {
        self.path = path
        self.exceptions = exceptions
        self.resolvedPaths = resolvedPaths
    }
}
