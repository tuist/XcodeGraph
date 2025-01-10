import Path
import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeProjMapper

@Suite
struct XCConfigurationMapperTests {
    let mapper = XCConfigurationMapper()

    @Test("Returns default settings when configuration list is nil")
    func testNilConfigurationListReturnsDefault() throws {
        let mockProvider = MockProjectProvider()
        let settings = try mapper.map(xcodeProj: mockProvider.xcodeProj, configurationList: nil)
        #expect(settings == Settings.default)
    }

    @Test("Maps a single build configuration correctly")
    func testSingleConfigurationMapping() throws {
        let pbxProj = PBXProj()
        let config: XCBuildConfiguration = .testDebug().add(to: pbxProj)
        let configList = XCConfigurationList.test(
            buildConfigurations: [config],
            defaultConfigurationName: "Debug"
        ).add(to: pbxProj)
        let mockProvider = MockProjectProvider(configurationList: configList, pbxProj: pbxProj)

        let settings = try mapper.map(xcodeProj: mockProvider.xcodeProj, configurationList: configList)
        #expect(settings.configurations.count == 1)

        let configKey = settings.configurations.keys.first
        try #require(configKey != nil)
        #expect(configKey?.name == "Debug")
        #expect(configKey?.variant == .debug)

        let debugConfig = try #require(settings.configurations[configKey!])
        #expect(debugConfig?.settings["PRODUCT_BUNDLE_IDENTIFIER"] == "com.example.debug")
    }

    @Test("Maps multiple build configurations correctly")
    func testMultipleConfigurations() throws {
        let pbxProj = PBXProj()

        let debugConfiguration: XCBuildConfiguration = .testDebug().add(to: pbxProj)
        let releaseConfiguration: XCBuildConfiguration = .testRelease().add(to: pbxProj)
        let configs = [debugConfiguration, releaseConfiguration]
        let configList = XCConfigurationList.test(buildConfigurations: configs).add(to: pbxProj)
        let mockProvider = MockProjectProvider(configurationList: configList, pbxProj: pbxProj)

        let settings = try mapper.map(xcodeProj: mockProvider.xcodeProj, configurationList: configList)
        #expect(settings.configurations.count == 2)

        let debugKey = try #require(settings.configurations.keys.first { $0.name == "Debug" })
        let releaseKey = try #require(settings.configurations.keys.first { $0.name == "Release" })

        #expect(debugKey.variant == .debug)
        #expect(releaseKey.variant == .release)

        let debugConfig = try #require(settings.configurations[debugKey])
        let releaseConfig = try #require(settings.configurations[releaseKey])

        #expect(debugConfig?.settings["PRODUCT_BUNDLE_IDENTIFIER"] == "com.example.debug")
        #expect(releaseConfig?.settings["PRODUCT_BUNDLE_IDENTIFIER"] == "com.example.release")
    }

    @Test("Coerces non-string values to strings in build settings")
    func testCoercionOfNonStringValues() throws {
        let pbxProj = PBXProj()

        let config: XCBuildConfiguration = .testDebug(buildSettings: ["SOME_NUMBER": 42, "A_BOOL": true]).add(to: pbxProj)

        let configList = XCConfigurationList.test(buildConfigurations: [config]).add(to: pbxProj)
        let mockProvider = MockProjectProvider(configurationList: configList)

        let settings = try mapper.map(xcodeProj: mockProvider.xcodeProj, configurationList: configList)
        let debugKey = try #require(settings.configurations.keys.first { $0.name == "Debug" })
        let debugConfig = try #require(settings.configurations[debugKey])

        #expect(debugConfig?.settings["SOME_NUMBER"] == "42")
    }

    @Test("Resolves XCConfig file paths correctly")
    func testXCConfigPathResolution() throws {
        let pbxProj = MockProjectProvider().pbxProj
        let baseConfigRef = try PBXFileReference.test(
            sourceTree: .sourceRoot, path: "Config.xcconfig"
        ).add(to: pbxProj).addToMainGroup(in: pbxProj)

        let buildConfig = XCBuildConfiguration.testDebug(
            buildSettings: ["PRODUCT_BUNDLE_IDENTIFIER": "com.example"]
        ).add(to: pbxProj)
        buildConfig.baseConfiguration = baseConfigRef

        let configList = XCConfigurationList(
            buildConfigurations: [buildConfig],
            defaultConfigurationName: "Debug",
            defaultConfigurationIsVisible: false
        )

        let mockProvider = MockProjectProvider(
            sourceDirectory: "/Users/test/project",
            configurationList: configList
        )
        let settings = try mapper.map(xcodeProj: mockProvider.xcodeProj, configurationList: configList)

        let debugKey = try #require(settings.configurations.keys.first { $0.name == "Debug" })
        let debugConfig = try #require(settings.configurations[debugKey])

        let expectedPath = "/Users/test/project/Config.xcconfig"
        #expect(debugConfig?.xcconfig?.pathString == expectedPath)
    }

    @Test("Maps array values correctly in build settings")
    func testArrayValueMapping() throws {
        let pbxProj = PBXProj()

        let config: XCBuildConfiguration = .testDebug(buildSettings: ["SOME_ARRAY": ["val1", "val2"]]).add(to: pbxProj)

        let configList = XCConfigurationList.test(buildConfigurations: [config]).add(to: pbxProj)
        let mockProvider = MockProjectProvider(configurationList: configList, pbxProj: pbxProj)

        let settings = try mapper.map(xcodeProj: mockProvider.xcodeProj, configurationList: configList)

        #expect(settings.configurations.count == 1)
        let debugKey = try #require(settings.configurations.keys.first { $0.name == "Debug" })
        let debugConfig = try #require(settings.configurations[debugKey])

        #expect(debugConfig?.settings["SOME_ARRAY"] == ["val1", "val2"])
    }
}
