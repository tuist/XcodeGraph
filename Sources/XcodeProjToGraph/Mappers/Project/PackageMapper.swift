import Foundation
import Path
import XcodeGraph
import XcodeProj

/// A protocol for mapping `XCSwiftPackageReference` instances to `Package` models.
protocol PackageMapping: Sendable {
    /// Maps a remote Swift package reference to a `Package`.
    ///
    /// - Parameter package: The remote Swift package reference.
    /// - Returns: A `Package` representing the remote package.
    /// - Throws: If required repository information is missing or invalid.
    func map(package: XCRemoteSwiftPackageReference) async throws -> Package

    /// Maps a local Swift package reference to a `Package`.
    ///
    /// - Parameter package: The local Swift package reference.
    /// - Returns: A `Package` representing the local package.
    /// - Throws: If the package path cannot be validated.
    func map(package: XCLocalSwiftPackageReference) async throws -> Package
}

/// A mapper that converts remote and local Swift package references into `Package` models.
///
/// The `PackageMapper` uses the provided `ProjectProviding` to resolve local package paths relative
/// to the project's source directory. For remote packages, it uses the repository URL and version requirement
/// from the `XCRemoteSwiftPackageReference` to construct a `Package` with the appropriate `Requirement`.
final class PackageMapper: PackageMapping {
    private let projectProvider: ProjectProviding

    /// Creates a new `PackageMapper`.
    ///
    /// - Parameter projectProvider: A provider that offers access to the project's directory structure
    ///   and additional metadata.
    init(projectProvider: ProjectProviding) {
        self.projectProvider = projectProvider
    }

    /// Maps an `XCRemoteSwiftPackageReference` to a `Package`.
    ///
    /// - Parameter package: The `XCRemoteSwiftPackageReference` to map.
    /// - Returns: A `Package` instance representing the mapped remote package.
    /// - Throws: `MappingError.missingRepositoryURL` if the repository URL is not found.
    public func map(package: XCRemoteSwiftPackageReference) async throws -> Package {
        guard let repositoryURL = package.repositoryURL else {
            throw MappingError.missingRepositoryURL(packageName: package.name ?? "Unknown Package")
        }

        let requirement = await mapRequirement(package: package)
        return .remote(url: repositoryURL, requirement: requirement)
    }

    /// Maps an `XCLocalSwiftPackageReference` to a `Package`.
    ///
    /// - Parameter package: The `XCLocalSwiftPackageReference` to map.
    /// - Returns: A `Package` instance representing the mapped local package.
    /// - Throws: If the relative path is invalid.
    public func map(package: XCLocalSwiftPackageReference) async throws -> Package {
        let relativePath = try RelativePath(validating: package.relativePath)
        let path = projectProvider.sourceDirectory.appending(relativePath)
        return .local(path: path)
    }

    /// Maps the version requirement of an `XCRemoteSwiftPackageReference` to a `Package.Requirement`.
    ///
    /// This method converts the version requirement specified in the Xcode project into a `Requirement`
    /// used by the internal `Package` model. It supports all standard SwiftPM versioning schemes,
    /// including major/minor constraints, exact versions, ranges, branches, and revisions.
    ///
    /// - Parameter package: The `XCRemoteSwiftPackageReference` whose requirement to map.
    /// - Returns: A `Package.Requirement` representing the version requirement.
    public func mapRequirement(package: XCRemoteSwiftPackageReference) async -> Requirement {
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
