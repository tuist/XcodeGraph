import Path
import Testing
import XcodeGraph
import XcodeProj

@testable import TestSupport
@testable import XcodeProjToGraph

struct PackageMapperTests {
  let mapper: PackageMapper
  let projectProvider: MockProjectProvider

  init() {
    let provider = MockProjectProvider()
    self.projectProvider = provider
    self.mapper = PackageMapper(projectProvider: provider)
  }

  @Test func testMapPackageWithValidURL() async throws {
    let package = XCRemoteSwiftPackageReference.mock(
      repositoryURL: "https://github.com/example/package.git",
      versionRequirement: .upToNextMajorVersion("1.0.0")
    )

    let result = try await mapper.map(package: package)
    #expect(
      result
        == .remote(
          url: "https://github.com/example/package.git", requirement: .upToNextMajor("1.0.0")))
  }

  @Test func testMapRequirementUpToNextMajor() async throws {
    let package = XCRemoteSwiftPackageReference.mock(
      repositoryURL: "https://github.com/example/package.git",
      versionRequirement: .upToNextMajorVersion("1.0.0")
    )

    let requirement = await mapper.mapRequirement(package: package)
    #expect(requirement == .upToNextMajor("1.0.0"))
  }

  @Test func testMapRequirementUpToNextMinor() async throws {
    let package = XCRemoteSwiftPackageReference.mock(
      repositoryURL: "https://github.com/example/package.git",
      versionRequirement: .upToNextMinorVersion("1.2.0")
    )

    let requirement = await mapper.mapRequirement(package: package)
    #expect(requirement == .upToNextMinor("1.2.0"))
  }

  @Test func testMapRequirementExact() async throws {
    let package = XCRemoteSwiftPackageReference.mock(
      repositoryURL: "https://github.com/example/package.git",
      versionRequirement: .exact("1.2.3")
    )

    let requirement = await mapper.mapRequirement(package: package)
    #expect(requirement == .exact("1.2.3"))
  }

  @Test func testMapRequirementRange() async throws {
    let package = XCRemoteSwiftPackageReference.mock(
      repositoryURL: "https://github.com/example/package.git",
      versionRequirement: .range(from: "1.0.0", to: "2.0.0")
    )

    let requirement = await mapper.mapRequirement(package: package)
    #expect(requirement == .range(from: "1.0.0", to: "2.0.0"))
  }

  @Test func testMapRequirementBranch() async throws {
    let package = XCRemoteSwiftPackageReference.mock(
      repositoryURL: "https://github.com/example/package.git",
      versionRequirement: .branch("main")
    )

    let requirement = await mapper.mapRequirement(package: package)
    #expect(requirement == .branch("main"))
  }

  @Test func testMapRequirementRevision() async throws {
    let package = XCRemoteSwiftPackageReference.mock(
      repositoryURL: "https://github.com/example/package.git",
      versionRequirement: .revision("abc123")
    )

    let requirement = await mapper.mapRequirement(package: package)
    #expect(requirement == .revision("abc123"))
  }

  @Test func testMapRequirementNoVersionRequirement() async throws {
    let package = XCRemoteSwiftPackageReference.mock(
      repositoryURL: "https://github.com/example/package.git",
      versionRequirement: nil
    )

    let requirement = await mapper.mapRequirement(package: package)
    #expect(requirement == .upToNextMajor("0.0.0"))
  }

  @Test func testMapLocalPackage() async throws {
    // Arrange
    let localPackage = XCLocalSwiftPackageReference.mock(relativePath: "Packages/Example")

    // Act
    let result = try await mapper.map(package: localPackage)

    // Assert
    let expectedPath = projectProvider.sourceDirectory.appending(
      try RelativePath(validating: "Packages/Example"))
    #expect(result == .local(path: expectedPath))
  }
}

// Extension to support testing
extension XCRemoteSwiftPackageReference {
  static func mock(
    repositoryURL: String,
    versionRequirement: VersionRequirement?
  ) -> XCRemoteSwiftPackageReference {
    return XCRemoteSwiftPackageReference(
      repositoryURL: repositoryURL,
      versionRequirement: versionRequirement
    )
  }
}

extension XCLocalSwiftPackageReference {
  static func mock(relativePath: String) -> XCLocalSwiftPackageReference {
    return XCLocalSwiftPackageReference(relativePath: relativePath)
  }
}
