import Path
import Testing
import XcodeGraph
import XcodeProj

@testable import TestSupport
@testable import XcodeProjToGraph

struct PBXTargetMapperTests {
  let mockProvider = MockProjectProvider()
  let mapper: TargetMapping

  init() {
    self.mapper = TargetMapper(projectProvider: mockProvider)
  }

  @Test func testMapBasicTarget() async throws {
    let target = createTarget(
      name: "App",
      productType: .application,
      buildSettings: ["PRODUCT_BUNDLE_IDENTIFIER": "com.example.app"]
    )

    let mapped = try await mapper.map(pbxTarget: target)
    #expect(mapped.name == "App")
    #expect(mapped.product == .app)
    #expect(mapped.productName == "App")
    #expect(mapped.bundleId == "com.example.app")

  }

  @Test func testMapTargetWithMissingBundleId() async throws {
    let target = createTarget(
      name: "App",
      productType: .application,
      buildSettings: [:]
    )

    await #expect(throws: MappingError.missingBundleIdentifier(targetName: "App")) {
      _ = try await mapper.map(pbxTarget: target)
    }
  }

  @Test func testMapTargetWithEnvironmentVariables() async throws {
    let target = createTarget(
      name: "App",
      productType: .application,
      buildSettings: [
        "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
        "ENVIRONMENT_VARIABLES": ["TEST_VAR": "test_value"],
      ]
    )

    let mapped = try await mapper.map(pbxTarget: target)
    #expect(mapped.environmentVariables["TEST_VAR"]?.value == "test_value")
    #expect(mapped.environmentVariables["TEST_VAR"]?.isEnabled == true)
  }

  @Test func testMapTargetWithLaunchArguments() async throws {
    let target = createTarget(
      name: "App",
      productType: .application,
      buildSettings: [
        "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
        "LAUNCH_ARGUMENTS": ["-debug", "--verbose"],
      ]
    )

    let mapped = try await mapper.map(pbxTarget: target)
    let expected = [
      LaunchArgument(name: "-debug", isEnabled: true),
      LaunchArgument(name: "--verbose", isEnabled: true),
    ]
    #expect(mapped.launchArguments == expected)

  }

  @Test func testMapTargetWithSourceFiles() async throws {
    let sourceFile = PBXFileReference.mock(
      path: "ViewController.swift",
      lastKnownFileType: "sourcecode.swift",
      pbxProj: mockProvider.pbxProj
    )
    let buildFile = PBXBuildFile.mock(file: sourceFile, pbxProj: mockProvider.pbxProj)
    let sourcesPhase = PBXSourcesBuildPhase.mock(files: [buildFile], pbxProj: mockProvider.pbxProj)

    let target = createTarget(
      name: "App",
      productType: .application,
      buildPhases: [sourcesPhase],
      buildSettings: ["PRODUCT_BUNDLE_IDENTIFIER": "com.example.app"]
    )

    let mapped = try await mapper.map(pbxTarget: target)
    #expect(mapped.sources.count == 1)
      #expect(mapped.sources[0].path.basename == "ViewController.swift")
  }

  @Test func testMapTargetWithMetadata() async throws {
    let target = createTarget(
      name: "App",
      productType: .application,
      buildSettings: [
        "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
        "TAGS": "tag1, tag2, tag3",
      ]
    )

    let mapped = try await mapper.map(pbxTarget: target)
    #expect(mapped.metadata.tags == Set(["tag1", "tag2", "tag3"]))
  }

  // MARK: - Helper Methods

  private func createTarget(
    name: String,
    productType: PBXProductType,
    buildPhases: [PBXBuildPhase] = [],
    buildSettings: [String: Any] = [:],
    dependencies: [PBXTargetDependency] = []
  ) -> PBXNativeTarget {
    let debugConfig = XCBuildConfiguration(
      name: "Debug",
      buildSettings: buildSettings
    )

    let releaseConfig = XCBuildConfiguration(
      name: "Release",
      buildSettings: buildSettings
    )

    let configurationList = XCConfigurationList(
      buildConfigurations: [debugConfig, releaseConfig],
      defaultConfigurationName: "Release"
    )

    mockProvider.pbxProj.add(object: debugConfig)
    mockProvider.pbxProj.add(object: releaseConfig)
    mockProvider.pbxProj.add(object: configurationList)

    let target = PBXNativeTarget.mock(
      name: name,
      buildConfigurationList: configurationList,
      buildRules: [],
      buildPhases: buildPhases,
      dependencies: dependencies,
      productType: productType,
      pbxProj: mockProvider.pbxProj
    )

    return target
  }
}
