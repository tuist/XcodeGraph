import Path
import Testing
import XcodeGraph
import XcodeProj

@testable import TestSupport
@testable import XcodeProjToGraph

@Suite
struct SettingsMapperTests {
    let mapper = SettingsMapper()

    @Test("Returns default settings when configuration list is nil")
    func testNilConfigurationListReturnsDefault() async throws {
        let mockProvider = MockProjectProvider()
        let settings = try await mapper.map(projectProvider: mockProvider, configurationList: nil)
        #expect(settings == Settings.default)
    }

    @Test("Maps a single build configuration correctly")
    func testSingleConfigurationMapping() async throws {
        let pbxProj = PBXProj()
        let configList = XCConfigurationList.mock(
            configs: [("Debug", ["PRODUCT_BUNDLE_IDENTIFIER": "com.example.debug"])],
            proj: pbxProj
        )
        let mockProvider = MockProjectProvider(configurationList: configList, pbxProj: pbxProj)

        let settings = try await mapper.map(projectProvider: mockProvider, configurationList: configList)
        #expect(settings.configurations.count == 1)

        let configKey = settings.configurations.keys.first
        try #require(configKey != nil)
        #expect(configKey?.name == "Debug")
        #expect(configKey?.variant == .debug)

        let debugConfig = try #require(settings.configurations[configKey!])
        #expect(debugConfig?.settings["PRODUCT_BUNDLE_IDENTIFIER"] == "com.example.debug")
    }

    @Test("Maps multiple build configurations correctly")
    func testMultipleConfigurations() async throws {
        let pbxProj = PBXProj()
        let configs: [(String, [String: Sendable])] = [
            ("Debug", ["PRODUCT_BUNDLE_IDENTIFIER": "com.example.debug"]),
            ("Release", ["PRODUCT_BUNDLE_IDENTIFIER": "com.example.release"]),
        ]
        let configList = XCConfigurationList.mock(configs: configs, proj: pbxProj)
        let mockProvider = MockProjectProvider(configurationList: configList, pbxProj: pbxProj)

        let settings = try await mapper.map(projectProvider: mockProvider, configurationList: configList)
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
    func testCoercionOfNonStringValues() async throws {
        let pbxProj = PBXProj()
        let configs: [(String, [String: Sendable])] = [
            ("Debug", ["SOME_NUMBER": 42]),
        ]
        let configList = XCConfigurationList.mock(configs: configs, proj: pbxProj)
        let mockProvider = MockProjectProvider(configurationList: configList)

        let settings = try await mapper.map(projectProvider: mockProvider, configurationList: configList)
        let debugKey = try #require(settings.configurations.keys.first { $0.name == "Debug" })
        let debugConfig = try #require(settings.configurations[debugKey])

        #expect(debugConfig?.settings["SOME_NUMBER"] == "42")
    }

    @Test("Resolves XCConfig file paths correctly")
    func testXCConfigPathResolution() async throws {
        let pbxProj = PBXProj()
        let baseConfigRef = PBXFileReference.mock(
            sourceTree: .sourceRoot, path: "Config.xcconfig", pbxProj: pbxProj
        )
        let buildConfig = XCBuildConfiguration.mock(
            name: "Debug",
            buildSettings: ["PRODUCT_BUNDLE_IDENTIFIER": "com.example"],
            pbxProj: pbxProj
        )
        buildConfig.baseConfiguration = baseConfigRef

        let configList = XCConfigurationList(
            buildConfigurations: [buildConfig],
            defaultConfigurationName: "Debug",
            defaultConfigurationIsVisible: false
        )

        let mockProvider = MockProjectProvider(
            sourceDirectory: "/Users/test/project", configurationList: configList
        )
        let settings = try await mapper.map(projectProvider: mockProvider, configurationList: configList)

        let debugKey = try #require(settings.configurations.keys.first { $0.name == "Debug" })
        let debugConfig = try #require(settings.configurations[debugKey])

        let expectedPath = "/Users/test/project/Config.xcconfig"
        #expect(debugConfig?.xcconfig?.pathString == expectedPath)
    }

    @Test("Maps array values correctly in build settings")
    func testArrayValueMapping() async throws {
        let pbxProj = PBXProj()
        let configs: [(String, [String: Sendable])] = [
            ("Debug", ["SOME_ARRAY": ["val1", "val2"]]),
        ]
        let configList = XCConfigurationList.mock(configs: configs, proj: pbxProj)
        let mockProvider = MockProjectProvider(configurationList: configList, pbxProj: pbxProj)

        let settings = try await mapper.map(projectProvider: mockProvider, configurationList: configList)

        #expect(settings.configurations.count == 1)
        let debugKey = try #require(settings.configurations.keys.first { $0.name == "Debug" })
        let debugConfig = try #require(settings.configurations[debugKey])

        #expect(debugConfig?.settings["SOME_ARRAY"] == ["val1", "val2"])
    }
}
