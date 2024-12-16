import Path
import Testing
import XcodeGraph
import XcodeProj

@testable import TestSupport
@testable import XcodeProjToGraph

@Suite
struct PackageMapperTests {
    let mapper: PackageMapper
    let projectProvider: MockProjectProvider

    init() {
        let provider = MockProjectProvider()
        projectProvider = provider
        mapper = PackageMapper(projectProvider: provider)
    }

    @Test("Maps a remote package with a valid URL and up-to-next-major requirement")
    func testMapPackageWithValidURL() async throws {
        let package = XCRemoteSwiftPackageReference.mock(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .upToNextMajorVersion("1.0.0")
        )

        let result = try await mapper.map(package: package)
        #expect(
            result == .remote(
                url: "https://github.com/example/package.git", requirement: .upToNextMajor("1.0.0")
            )
        )
    }

    @Test("Maps an up-to-next-major version requirement correctly")
    func testMapRequirementUpToNextMajor() async throws {
        let package = XCRemoteSwiftPackageReference.mock(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .upToNextMajorVersion("1.0.0")
        )

        let requirement = await mapper.mapRequirement(package: package)
        #expect(requirement == .upToNextMajor("1.0.0"))
    }

    @Test("Maps an up-to-next-minor version requirement correctly")
    func testMapRequirementUpToNextMinor() async throws {
        let package = XCRemoteSwiftPackageReference.mock(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .upToNextMinorVersion("1.2.0")
        )

        let requirement = await mapper.mapRequirement(package: package)
        #expect(requirement == .upToNextMinor("1.2.0"))
    }

    @Test("Maps an exact version requirement correctly")
    func testMapRequirementExact() async throws {
        let package = XCRemoteSwiftPackageReference.mock(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .exact("1.2.3")
        )

        let requirement = await mapper.mapRequirement(package: package)
        #expect(requirement == .exact("1.2.3"))
    }

    @Test("Maps a range version requirement correctly")
    func testMapRequirementRange() async throws {
        let package = XCRemoteSwiftPackageReference.mock(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .range(from: "1.0.0", to: "2.0.0")
        )

        let requirement = await mapper.mapRequirement(package: package)
        #expect(requirement == .range(from: "1.0.0", to: "2.0.0"))
    }

    @Test("Maps a branch-based version requirement correctly")
    func testMapRequirementBranch() async throws {
        let package = XCRemoteSwiftPackageReference.mock(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .branch("main")
        )

        let requirement = await mapper.mapRequirement(package: package)
        #expect(requirement == .branch("main"))
    }

    @Test("Maps a revision-based version requirement correctly")
    func testMapRequirementRevision() async throws {
        let package = XCRemoteSwiftPackageReference.mock(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .revision("abc123")
        )

        let requirement = await mapper.mapRequirement(package: package)
        #expect(requirement == .revision("abc123"))
    }

    @Test("Maps a missing version requirement to up-to-next-major(0.0.0)")
    func testMapRequirementNoVersionRequirement() async throws {
        let package = XCRemoteSwiftPackageReference.mock(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: nil
        )

        let requirement = await mapper.mapRequirement(package: package)
        #expect(requirement == .upToNextMajor("0.0.0"))
    }

    @Test("Maps a local package reference correctly")
    func testMapLocalPackage() async throws {
        let localPackage = XCLocalSwiftPackageReference.mock(relativePath: "Packages/Example")

        let result = try await mapper.map(package: localPackage)

        let expectedPath = projectProvider.sourceDirectory.appending(
            try RelativePath(validating: "Packages/Example")
        )
        #expect(result == .local(path: expectedPath))
    }
}
