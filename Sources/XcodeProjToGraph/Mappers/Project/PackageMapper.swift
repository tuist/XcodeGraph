import Foundation
import Path
import XcodeGraph
import XcodeProj

/// A protocol defining how to map both remote and local Swift package references into `Package` models.
///
/// Conforming types provide methods to translate `XCRemoteSwiftPackageReference` and `XCLocalSwiftPackageReference`
/// objects into `Package` instances, resolving URLs, version requirements, and file paths as needed.
protocol PackageMapping: Sendable {
    /// Maps a remote Swift package reference to a `Package`.
    ///
    /// This method inspects the repository URL and version requirement from the provided `XCRemoteSwiftPackageReference`
    /// and constructs a `Package` model that can be integrated into the overall project graph.
    ///
    /// - Parameter package: The remote Swift package reference.
    /// - Returns: A `Package` representing the remote package, including its URL and version requirement.
    /// - Throws: `MappingError.missingRepositoryURL` if the remote package has no repository URL.
    func map(package: XCRemoteSwiftPackageReference) async throws -> Package

    /// Maps a local Swift package reference to a `Package`.
    ///
    /// This method resolves the provided local package path relative to the project's source directory,
    /// constructing a `.local` `Package` model that can be used in the project graph.
    ///
    /// - Parameter package: The local Swift package reference.
    /// - Returns: A `Package` representing the local package, including its resolved filesystem path.
    /// - Throws: If the provided path is invalid or cannot be resolved relative to the project's source directory.
    func map(package: XCLocalSwiftPackageReference) async throws -> Package
}

/// A mapper that converts remote and local Swift package references into domain `Package` models.
///
/// `PackageMapper` uses `ProjectProviding` to resolve paths and retrieves remote package information from
/// `XCRemoteSwiftPackageReference`
/// instances. By extracting repository URLs, version requirements, and local paths, `PackageMapper` produces `Package`
/// models that can be integrated into a broader Xcode project graph.
///
/// Example usage:
/// ```swift
/// let packageMapper = PackageMapper(projectProvider: provider)
/// let remotePackage = try await packageMapper.map(package: remoteRef)
/// let localPackage = try await packageMapper.map(package: localRef)
/// ```
public final class PackageMapper: PackageMapping {
    private let projectProvider: ProjectProviding

    /// Creates a new `PackageMapper` with the given project provider.
    ///
    /// - Parameter projectProvider: Provides access to the project's directory structure and metadata,
    ///   enabling resolution of local package paths and contextual validation.
    init(projectProvider: ProjectProviding) {
        self.projectProvider = projectProvider
    }

    public func map(package: XCRemoteSwiftPackageReference) async throws -> Package {
        guard let repositoryURL = package.repositoryURL else {
            throw MappingError.missingRepositoryURL(packageName: package.name ?? "Unknown Package")
        }

        let requirement = mapRequirement(package: package)
        return .remote(url: repositoryURL, requirement: requirement)
    }

    public func map(package: XCLocalSwiftPackageReference) async throws -> Package {
        let relativePath = try RelativePath(validating: package.relativePath)
        let path = projectProvider.sourceDirectory.appending(relativePath)
        return .local(path: path)
    }

    /// Maps the version requirement of a remote Swift package to a `Package.Requirement`.
    ///
    /// By examining the `XCRemoteSwiftPackageReference`'s `versionRequirement`, this method determines the correct
    /// versioning scheme (exact, range, branch, revision, or up-to-next-major/minor) and returns a `Requirement`
    /// that captures this information.
    ///
    /// - Parameter package: The `XCRemoteSwiftPackageReference` containing the version requirement.
    /// - Returns: A `Package.Requirement` reflecting the specified versioning scheme.
    public func mapRequirement(package: XCRemoteSwiftPackageReference) -> Requirement {
        guard let versionRequirement = package.versionRequirement else {
            return .upToNextMajor("0.0.0")
        }

        switch versionRequirement {
        case let .upToNextMajorVersion(version):
            return .upToNextMajor(version)
        case let .upToNextMinorVersion(version):
            return .upToNextMinor(version)
        case let .exact(version):
            return .exact(version)
        case let .range(lowerBound, upperBound):
            return .range(from: lowerBound, to: upperBound)
        case let .branch(branch):
            return .branch(branch)
        case let .revision(revision):
            return .revision(revision)
        }
    }
}
