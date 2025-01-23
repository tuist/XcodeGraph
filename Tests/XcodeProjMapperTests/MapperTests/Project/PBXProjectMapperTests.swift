import Path
import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeProjMapper

@Suite
struct PBXProjectMapperTests {

    @Test("Maps a basic project with default attributes")
    func testMapBasicProject() async throws {
        // Given
        let xcodeProj = MockProjectProvider().xcodeProj
        let mapper = PBXProjectMapper()

        // When
        let project = try await mapper.map(xcodeProj: xcodeProj)

        // Then
        #expect(project.name == "TestProject")
        #expect(project.path == xcodeProj.srcPath)
        #expect(project.sourceRootPath == xcodeProj.srcPath)
        #expect(project.xcodeProjPath == xcodeProj.projectPath)
        #expect(project.type == .local)
    }

    @Test("Maps a project with custom attributes (org name, class prefix, upgrade check)")
    func testMapProjectWithCustomAttributes() async throws {
        // Given
        let pbxProj = PBXProj()
        let mockProvider = MockProjectProvider(
            projectName: "CustomProject",
            pbxProj: pbxProj
        )
        let mapper = PBXProjectMapper()

        let customAttributes: [String: Any] = [
            "ORGANIZATIONNAME": "Example Org",
            "CLASSPREFIX": "EX",
            "LastUpgradeCheck": "1500",
        ]
        mockProvider.pbxProj.projects.first?.attributes = customAttributes

        // When
        let project = try await mapper.map(xcodeProj: mockProvider.xcodeProj)

        // Then
        #expect(project.name == "CustomProject")
        #expect(project.organizationName == "Example Org")
        #expect(project.classPrefix == "EX")
        #expect(project.lastUpgradeCheck == "1500")
    }

    @Test("Maps a project with remote package dependencies")
    func testMapProjectWithRemotePackages() async throws {
        // Given
        let mockProvider = MockProjectProvider()
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .upToNextMajorVersion("1.0.0")
        )
        mockProvider.pbxProj.add(object: package)
        try mockProvider.pbxProject().remotePackages.append(package)
        let mapper = PBXProjectMapper()

        // When
        let project = try await mapper.map(xcodeProj: mockProvider.xcodeProj)

        // Then
        #expect(project.packages.count == 1)
        guard case let .remote(url, requirement) = project.packages[0] else {
            Issue.record("Expected remote package")
            return
        }
        #expect(url == "https://github.com/example/package.git")
        #expect(requirement == .upToNextMajor("1.0.0"))
    }

    @Test("Maps a project with known regions")
    func testMapProjectWithKnownRegions() async throws {
        // Given
        let mockProvider = MockProjectProvider()
        try mockProvider.pbxProject().knownRegions = ["en", "es", "fr"]
        let mapper = PBXProjectMapper()

        // When
        let project = try await mapper.map(xcodeProj: mockProvider.xcodeProj)

        // Then
        #expect(project.defaultKnownRegions?.count == 3)
        #expect(project.defaultKnownRegions?.contains("en") == true)
        #expect(project.defaultKnownRegions?.contains("es") == true)
        #expect(project.defaultKnownRegions?.contains("fr") == true)
    }

    @Test("Maps a project with a custom development region")
    func testMapProjectWithDevelopmentRegion() async throws {
        // Given
        let mockProvider = MockProjectProvider()
        try mockProvider.pbxProject().developmentRegion = "fr"
        let mapper = PBXProjectMapper()

        // When
        let project = try await mapper.map(xcodeProj: mockProvider.xcodeProj)

        // Then
        #expect(project.developmentRegion == "fr")
    }

    @Test("Maps a project with default resource synthesizers")
    func testMapProjectWithResourceSynthesizers() async throws {
        // Given
        let mockProvider = MockProjectProvider()
        let mapper = PBXProjectMapper()

        // When
        let project = try await mapper.map(xcodeProj: mockProvider.xcodeProj)
        let synthesizers = project.resourceSynthesizers

        // Then
        // Check for strings synthesizer
        let stringsSynthesizer = synthesizers.first { $0.parser == .strings }
        #expect(stringsSynthesizer != nil)
        #expect(stringsSynthesizer?.extensions.contains("strings") == true)
        #expect(stringsSynthesizer?.extensions.contains("stringsdict") == true)

        // Check for assets synthesizer
        let assetsSynthesizer = synthesizers.first { $0.parser == .assets }
        #expect(assetsSynthesizer != nil)
        #expect(assetsSynthesizer?.extensions.contains("xcassets") == true)

        // Verify all expected synthesizer types are present
        let expectedParsers: Set<ResourceSynthesizer.Parser> = [
            .strings, .assets, .plists, .fonts, .coreData,
            .interfaceBuilder, .json, .yaml, .files, .stringsCatalog,
        ]
        let actualParsers = Set(synthesizers.map(\.parser))
        #expect(actualParsers == expectedParsers)
    }

    @Test("Maps a project with associated schemes")
    func testMapProjectWithSchemes() async throws {
        // Given
        let mockProvider = MockProjectProvider()
        let scheme = XCScheme.test(name: "TestScheme")
        mockProvider.xcodeProj.sharedData = XCSharedData(schemes: [scheme])
        let mapper = PBXProjectMapper()

        // When
        let project = try await mapper.map(xcodeProj: mockProvider.xcodeProj)

        // Then
        #expect(project.schemes.count == 1)
        #expect(project.schemes[0].name == "TestScheme")
    }
}
