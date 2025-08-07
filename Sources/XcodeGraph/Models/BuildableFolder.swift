import Path

/// A buildable folder maps to an PBXFileSystemSynchronizedRootGroup in Xcode projects.
/// Synchronized groups were introduced in Xcode 16 to reduce git conflicts by having a reference
/// to a folder whose content is "synchronized" by Xcode itself. Think of it as Xcode resolving
/// the globs.
public struct BuildableFolder: Sendable, Codable {
    /// The absolute path to the buildable folder.
    public var path: AbsolutePath

    /// Creates an instance of buildable folder.
    /// - Parameter path: Absolute path to the buildable folder.
    public init(path: AbsolutePath) {
        self.path = path
    }
}
