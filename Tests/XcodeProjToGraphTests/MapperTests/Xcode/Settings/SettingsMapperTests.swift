import Path
import Testing
import XcodeGraph
import XcodeProj

@testable import TestSupport  // For MockFactory usage
@testable import XcodeProjToGraph

struct SettingsMapperTests {
  let mapper = SettingsMapper()

  @Test func testNilConfigurationListReturnsDefault() async throws {
    let mockProvider = MockProjectProvider()
    let settings = try await mapper.map(projectProvider: mockProvider, configurationList: nil)
    #expect(settings == Settings.default)
  }

  @Test func testSingleConfigurationMapping() async throws {
    let pbxProj = PBXProj()
    let configList = XCConfigurationList.mock(
      configs: [("Debug", ["PRODUCT_BUNDLE_IDENTIFIER": "com.example.debug"])], proj: pbxProj
    )
    let mockProvider = MockProjectProvider(configurationList: configList, pbxProj: pbxProj)

    let settings = try await mapper.map(
      projectProvider: mockProvider, configurationList: configList)
    #expect(settings.configurations.count == 1)

    let configKey = settings.configurations.keys.first
    try #require(configKey != nil)
    #expect(configKey?.name == "Debug")
    #expect(configKey?.variant == .debug)

    let debugConfig = settings.configurations[configKey!]
    try #require(debugConfig != nil)

    // Now `debugConfig` is a `Configuration?`.
    let actualDebugConfig = debugConfig!
    try #require(actualDebugConfig != nil)

    #expect(actualDebugConfig!.settings["PRODUCT_BUNDLE_IDENTIFIER"] == "com.example.debug")
  }

  @Test func testMultipleConfigurations() async throws {
    let pbxProj = PBXProj()
    let configs: [(String, [String: Sendable])] = [
      ("Debug", ["PRODUCT_BUNDLE_IDENTIFIER": "com.example.debug"]),
      ("Release", ["PRODUCT_BUNDLE_IDENTIFIER": "com.example.release"]),
    ]
    let configList = XCConfigurationList.mock(configs: configs, proj: pbxProj)
    let mockProvider = MockProjectProvider(configurationList: configList, pbxProj: pbxProj)

    let settings = try await mapper.map(
      projectProvider: mockProvider, configurationList: configList)
    #expect(settings.configurations.count == 2)

    let debugKey = settings.configurations.keys.first { $0.name == "Debug" }
    let releaseKey = settings.configurations.keys.first { $0.name == "Release" }

    try #require(debugKey != nil)
    try #require(releaseKey != nil)
    #expect(debugKey?.variant == .debug)
    #expect(releaseKey?.variant == .release)

    let debugConfig = settings.configurations[debugKey!]
    let releaseConfig = settings.configurations[releaseKey!]

    try #require(debugConfig != nil)
    try #require(releaseConfig != nil)

    let actualDebugConfig = debugConfig!
    let actualReleaseConfig = releaseConfig!

    #expect(actualDebugConfig?.settings["PRODUCT_BUNDLE_IDENTIFIER"] == "com.example.debug")
    #expect(actualReleaseConfig?.settings["PRODUCT_BUNDLE_IDENTIFIER"] == "com.example.release")
  }

  @Test func testCoercionOfNonStringValues() async throws {
    let pbxProj = PBXProj()
    let configs: [(String, [String: Sendable])] = [
      ("Debug", ["SOME_NUMBER": 42])
    ]
    let configList = XCConfigurationList.mock(configs: configs, proj: pbxProj)
    let mockProvider = MockProjectProvider(configurationList: configList)

    let settings = try await mapper.map(
      projectProvider: mockProvider, configurationList: configList)
    let debugKey = settings.configurations.keys.first { $0.name == "Debug" }
    try #require(debugKey != nil)

    let debugConfig = settings.configurations[debugKey!]
    try #require(debugConfig != nil)

    let actualDebugConfig = debugConfig!
    try #require(actualDebugConfig != nil)

    #expect(actualDebugConfig!.settings["SOME_NUMBER"] == "42")
  }

  @Test func testXCConfigPathResolution() async throws {
    let pbxProj = PBXProj()
    let baseConfigRef = PBXFileReference.mock(
      sourceTree: .sourceRoot, path: "Config.xcconfig", pbxProj: pbxProj)
    let buildConfig = XCBuildConfiguration.mock(
      name: "Debug", buildSettings: ["PRODUCT_BUNDLE_IDENTIFIER": "com.example"],
      pbxProj: pbxProj)
    buildConfig.baseConfiguration = baseConfigRef

    let configList = XCConfigurationList(
      buildConfigurations: [buildConfig],
      defaultConfigurationName: "Debug",
      defaultConfigurationIsVisible: false
    )

    let mockProvider = MockProjectProvider(
      sourceDirectory: "/Users/test/project", configurationList: configList)
    let settings = try await mapper.map(
      projectProvider: mockProvider, configurationList: configList)

    let debugKey = settings.configurations.keys.first { $0.name == "Debug" }
    try #require(debugKey != nil)

    let debugConfig = settings.configurations[debugKey!]
    try #require(debugConfig != nil)

    let actualDebugConfig = debugConfig!
    try #require(actualDebugConfig != nil)

    let expectedPath = "/Users/test/project/Config.xcconfig"
    #expect(actualDebugConfig!.xcconfig?.pathString == expectedPath)
  }

  @Test func testArrayValueMapping() async throws {
    let pbxProj = PBXProj()
    let configs: [(String, [String: Sendable])] = [
      ("Debug", ["SOME_ARRAY": ["val1", "val2"]])
    ]
    let configList = XCConfigurationList.mock(configs: configs, proj: pbxProj)
    let mockProvider = MockProjectProvider(configurationList: configList, pbxProj: pbxProj)

    let settings = try await mapper.map(
      projectProvider: mockProvider, configurationList: configList)

    // Check we have one configuration
    #expect(settings.configurations.count == 1)

    // Retrieve the Debug configuration
    let debugKey = settings.configurations.keys.first { $0.name == "Debug" }
    try #require(debugKey != nil)
    let debugConfig = settings.configurations[debugKey!]
    try #require(debugConfig != nil)

    let actualDebugConfig = debugConfig!
    try #require(actualDebugConfig != nil)

    // Verify the array setting
    // NOTE: actualDebugConfig.settings["SOME_ARRAY"] should return a SettingValue
    // which is .array(["val1", "val2"])
    #expect(actualDebugConfig!.settings["SOME_ARRAY"] == ["val1", "val2"])
  }

}
