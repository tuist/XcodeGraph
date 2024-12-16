import Path
import Testing
import XcodeGraph
import XcodeProj

@testable import TestSupport
@testable import XcodeProjToGraph

@Suite
struct ProjectMapperTests {
    @Test("Maps a basic project with default attributes")
    func testMapBasicProject() async throws {
        let mockProvider = MockProjectProvider()
        let mapper = ProjectMapper(projectProvider: mockProvider)

        let project = try await mapper.mapProject()

        #expect(project.name == "TestProject")
        #expect(project.path == mockProvider.sourceDirectory)
        #expect(project.sourceRootPath == mockProvider.sourceDirectory)
        #expect(project.xcodeProjPath == mockProvider.sourceDirectory)
        #expect(project.type == .local)
    }

    @Test("Maps a project with custom attributes (org name, class prefix, upgrade check)")
    func testMapProjectWithCustomAttributes() async throws {
        let pbxProj = PBXProj()
        let provider = MockProjectProvider(
            projectName: "CustomProject",
            pbxProj: pbxProj
        )

        let mapper = ProjectMapper(projectProvider: provider)

        let customAttributes: [String: Any] = [
            "ORGANIZATIONNAME": "Example Org",
            "CLASSPREFIX": "EX",
            "LastUpgradeCheck": "1500",
        ]

        provider.pbxProj.projects.first?.attributes = customAttributes

        let project = try await mapper.mapProject()

        #expect(project.name == "CustomProject")
        #expect(project.organizationName == "Example Org")
        #expect(project.classPrefix == "EX")
        #expect(project.lastUpgradeCheck == "1500")
    }

    @Test("Maps a project that contains targets")
    func testMapProjectWithTargets() async throws {
        let mockProvider = MockProjectProvider()
        let configList = XCConfigurationList.mock(
            configs: [("Debug", ["PRODUCT_BUNDLE_IDENTIFIER": "com.example.app"])],
            proj: mockProvider.pbxProj
        )

        let mapper = ProjectMapper(projectProvider: mockProvider)

        let target = PBXNativeTarget.mock(
            name: "ExampleApp",
            buildConfigurationList: configList,
            productType: .application,
            pbxProj: mockProvider.pbxProj
        )
        try mockProvider.pbxProject().targets.append(target)

        let project = try await mapper.mapProject()

        #expect(project.targets.count == 1)
        #expect(project.targets.first?.value.name == "ExampleApp")
        #expect(project.targets.first?.value.product == .app)
    }

    @Test("Maps a project with remote package dependencies")
    func testMapProjectWithRemotePackages() async throws {
        let mockProvider = MockProjectProvider()
        let package = XCRemoteSwiftPackageReference(
            repositoryURL: "https://github.com/example/package.git",
            versionRequirement: .upToNextMajorVersion("1.0.0")
        )
        mockProvider.pbxProj.add(object: package)
        try mockProvider.pbxProject().remotePackages.append(package)
        let mapper = ProjectMapper(projectProvider: mockProvider)

        let project = try await mapper.mapProject()

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
        let mockProvider = MockProjectProvider()
        try mockProvider.pbxProject().knownRegions = ["en", "es", "fr"]
        let mapper = ProjectMapper(projectProvider: mockProvider)

        let project = try await mapper.mapProject()

        #expect(project.defaultKnownRegions?.count == 3)
        #expect(project.defaultKnownRegions?.contains("en") == true)
        #expect(project.defaultKnownRegions?.contains("es") == true)
        #expect(project.defaultKnownRegions?.contains("fr") == true)
    }

    @Test("Maps a project with a custom development region")
    func testMapProjectWithDevelopmentRegion() async throws {
        let mockProvider = MockProjectProvider()
        try mockProvider.pbxProject().developmentRegion = "fr"
        let mapper = ProjectMapper(projectProvider: mockProvider)

        let project = try await mapper.mapProject()

        #expect(project.developmentRegion == "fr")
    }

    @Test("Maps a project with default resource synthesizers")
    func testMapProjectWithResourceSynthesizers() async throws {
        let mockProvider = MockProjectProvider()
        let mapper = ProjectMapper(projectProvider: mockProvider)

        let project = try await mapper.mapProject()

        // Test for expected resource synthesizers
        let synthesizers = project.resourceSynthesizers

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
            .interfaceBuilder, .json, .yaml, .files,
        ]
        let actualParsers = Set(synthesizers.map(\.parser))
        #expect(actualParsers == expectedParsers)
    }

    @Test("Maps a project with associated schemes")
    func testMapProjectWithSchemes() async throws {
        let mockProvider = MockProjectProvider()
        let scheme = XCScheme.mock(name: "TestScheme")
        mockProvider.xcodeProj.sharedData = XCSharedData(schemes: [scheme])
        let mapper = ProjectMapper(projectProvider: mockProvider)

        let project = try await mapper.mapProject()

        #expect(project.schemes.count == 1)
        #expect(project.schemes[0].name == "TestScheme")
    }
}
