import Path
import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeProjMapper

@Suite
struct XCPackageMapperTests {
    let mapper: XCPackageMapper
    let xcodeProj: XcodeProj

    init() {
        xcodeProj = .test()
        mapper = XCPackageMapper()
    }

    @Test("Maps a remote package with a valid URL and up-to-next-major requirement")
    func testMapPackageWithValidURL() throws {
        // Given
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .upToNextMajorVersion("1.0.0")
        )

        // When
        let result = try mapper.map(package: package)

        // Then
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
        // Given
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .upToNextMajorVersion("1.0.0")
        )

        // When
        let requirement = mapper.mapRequirement(package: package)

        // Then
        #expect(requirement == .upToNextMajor("1.0.0"))
    }

    @Test("Maps an up-to-next-minor version requirement correctly")
    func testMapRequirementUpToNextMinor() throws {
        // Given
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .upToNextMinorVersion("1.2.0")
        )

        // When
        let requirement = mapper.mapRequirement(package: package)

        // Then
        #expect(requirement == .upToNextMinor("1.2.0"))
    }

    @Test("Maps an exact version requirement correctly")
    func testMapRequirementExact() throws {
        // Given
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .exact("1.2.3")
        )

        // When
        let requirement = mapper.mapRequirement(package: package)

        // Then
        #expect(requirement == .exact("1.2.3"))
    }

    @Test("Maps a range version requirement correctly")
    func testMapRequirementRange() throws {
        // Given
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .range(from: "1.0.0", to: "2.0.0")
        )

        // When
        let requirement = mapper.mapRequirement(package: package)

        // Then
        #expect(requirement == .range(from: "1.0.0", to: "2.0.0"))
    }

    @Test("Maps a branch-based version requirement correctly")
    func testMapRequirementBranch() throws {
        // Given
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .branch("main")
        )

        // When
        let requirement = mapper.mapRequirement(package: package)

        // Then
        #expect(requirement == .branch("main"))
    }

    @Test("Maps a revision-based version requirement correctly")
    func testMapRequirementRevision() throws {
        // Given
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .revision("abc123")
        )

        // When
        let requirement = mapper.mapRequirement(package: package)

        // Then
        #expect(requirement == .revision("abc123"))
    }

    @Test("Maps a missing version requirement to up-to-next-major(0.0.0)")
    func testMapRequirementNoVersionRequirement() throws {
        // Given
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: nil
        )

        // When
        let requirement = mapper.mapRequirement(package: package)

        // Then
        #expect(requirement == .upToNextMajor("0.0.0"))
    }

    @Test("Maps a local package reference correctly")
    func testMapLocalPackage() throws {
        // Given
        let localPackage = XCLocalSwiftPackageReference(relativePath: "Packages/Example")

        // When
        let result = try mapper.map(package: localPackage, sourceDirectory: xcodeProj.srcPath)

        // Then
        let expectedPath = xcodeProj.srcPath.appending(
            try RelativePath(validating: "Packages/Example")
        )
        #expect(result == .local(path: expectedPath))
    }

    @Test("Throws an error if remote package has no repository URL")
    func testMapPackageWithoutURL() async throws {
        // Given
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "",
            versionRequirement: .exact("1.2.3")
        )
        package.repositoryURL = nil

        // When / Then (expecting a throw)
        #expect {
            try mapper.map(package: package)
        } throws: { error in
            // Because 'repositoryURL' was set to nil,
            // we verify that the correct error message appears.
            return error.localizedDescription == "The repository URL is missing for the package: Unknown Package."
        }
    }
}
