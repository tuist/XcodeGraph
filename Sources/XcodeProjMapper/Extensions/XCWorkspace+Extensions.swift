import Foundation
import Path
import XcodeProj

extension XCWorkspace {
    /// Thrown if an `XCWorkspace` has no `path` despite our usage always expecting one.
    enum MissingWorkspacePathError: LocalizedError {
        case missingPath
        var errorDescription: String? {
            switch self {
            case .missingPath:
                return "XCWorkspace is missing a file path; this usage expects a valid path."
            }
        }
    }

    /// A computed property that either returns the workspace’s `path`
    /// or throws a `MissingWorkspacePathError` if it’s `nil`.
    public var pathOrThrow: AbsolutePath {
        get throws {
            guard let path else {
                throw MissingWorkspacePathError.missingPath
            }
            return try AbsolutePath(validating: path.string)
        }
    }
}

extension XcodeProj {
    /// Thrown if an `XcodeProj` has no `path` despite our usage always expecting one.
    enum MissingProjectPathError: LocalizedError {
        case missingPath
        var errorDescription: String? {
            switch self {
            case .missingPath:
                return "XcodeProj is missing a file path; this usage expects a valid path."
            }
        }
    }

    /// A computed property that either returns the project’s `path`
    /// or throws a `MissingProjectPathError` if it’s `nil`.
    public var pathOrThrow: AbsolutePath {
        get throws {
            guard let path else {
                throw MissingProjectPathError.missingPath
            }
            return try AbsolutePath(validating: path.string)
        }
    }

    public var srcPathOrThrow: AbsolutePath {
        get throws {
            try pathOrThrow.parentDirectory
        }
    }

    public var srcPathStringOrThrow: String {
        get throws {
            try srcPathOrThrow.pathString
        }
    }
}
