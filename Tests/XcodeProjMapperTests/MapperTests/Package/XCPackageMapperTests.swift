import Path
import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeProjMapper

@Suite
struct XCPackageMapperTests {
    let mapper: XCPackageMapper
    let projectProvider: MockProjectProvider

    init() {
        let provider = MockProjectProvider()
        projectProvider = provider
        mapper = XCPackageMapper()
    }

    @Test("Maps a remote package with a valid URL and up-to-next-major requirement")
    func testMapPackageWithValidURL() throws {
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .upToNextMajorVersion("1.0.0")
        )

        let result = try mapper.map(package: package)
        #expect(
            result
                == .remote(
                    url: "https://github.com/example/package.git",
                    requirement: .upToNextMajor("1.0.0")
                )
        )
    }

    @Test("Maps an up-to-next-major version requirement correctly")
    func testMapRequirementUpToNextMajor() throws {
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .upToNextMajorVersion("1.0.0")
        )

        let requirement = mapper.mapRequirement(package: package)
        #expect(requirement == .upToNextMajor("1.0.0"))
    }

    @Test("Maps an up-to-next-minor version requirement correctly")
    func testMapRequirementUpToNextMinor() throws {
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .upToNextMinorVersion("1.2.0")
        )

        let requirement = mapper.mapRequirement(package: package)
        #expect(requirement == .upToNextMinor("1.2.0"))
    }

    @Test("Maps an exact version requirement correctly")
    func testMapRequirementExact() throws {
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .exact("1.2.3")
        )

        let requirement = mapper.mapRequirement(package: package)
        #expect(requirement == .exact("1.2.3"))
    }

    @Test("Maps a range version requirement correctly")
    func testMapRequirementRange() throws {
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .range(from: "1.0.0", to: "2.0.0")
        )

        let requirement = mapper.mapRequirement(package: package)
        #expect(requirement == .range(from: "1.0.0", to: "2.0.0"))
    }

    @Test("Maps a branch-based version requirement correctly")
    func testMapRequirementBranch() throws {
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .branch("main")
        )

        let requirement = mapper.mapRequirement(package: package)
        #expect(requirement == .branch("main"))
    }

    @Test("Maps a revision-based version requirement correctly")
    func testMapRequirementRevision() throws {
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .revision("abc123")
        )

        let requirement = mapper.mapRequirement(package: package)
        #expect(requirement == .revision("abc123"))
    }

    @Test("Maps a missing version requirement to up-to-next-major(0.0.0)")
    func testMapRequirementNoVersionRequirement() throws {
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: nil
        )

        let requirement = mapper.mapRequirement(package: package)
        #expect(requirement == .upToNextMajor("0.0.0"))
    }

    @Test("Maps a local package reference correctly")
    func testMapLocalPackage() throws {
        let localPackage = XCLocalSwiftPackageReference(relativePath: "Packages/Example")
        let result = try mapper.map(package: localPackage, sourceDirectory: projectProvider.sourceDirectory)

        let expectedPath = projectProvider.sourceDirectory.appending(
            try RelativePath(validating: "Packages/Example")
        )
        #expect(result == .local(path: expectedPath))
    }

    @Test("Throws an error if remote package has no repository URL")
    func testMapPackageWithoutURL() async throws {
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "",
            versionRequirement: .exact("1.2.3")
        )
        package.repositoryURL = nil

        #expect {
            try mapper.map(package: package)
        } throws: { error in
            return error.localizedDescription == "The repository URL is missing for the package: Unknown Package."
        }
    }
}
