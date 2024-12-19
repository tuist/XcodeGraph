import Path
import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeProjMapper
import Foundation

@Suite
struct PBXTargetMapperTests {
    let mockProvider = MockProjectProvider()
    let mapper: TargetMapping

    init() {
        mapper = PBXTargetMapper()
    }

    @Test("Maps a basic target with a product bundle identifier")
    func testMapBasicTarget() throws {
        let target = createTarget(
            name: "App",
            productType: .application,
            buildSettings: ["PRODUCT_BUNDLE_IDENTIFIER": "com.example.app"]
        )

        let mapped = try mapper.map(pbxTarget: target, projectProvider: mockProvider)
        #expect(mapped.name == "App")
        #expect(mapped.product == .app)
        #expect(mapped.productName == "App")
        #expect(mapped.bundleId == "com.example.app")
    }

    @Test("Throws an error if the target is missing a bundle identifier")
    func testMapTargetWithMissingBundleId() throws {
        let target = createTarget(
            name: "App",
            productType: .application,
            buildSettings: [:]
        )

        #expect(throws: TargetMappingError.missingBundleIdentifier(targetName: "App")) {
            _ = try mapper.map(pbxTarget: target, projectProvider: mockProvider)
        }
    }

    @Test("Maps a target with environment variables")
    func testMapTargetWithEnvironmentVariables() throws {
        let target = createTarget(
            name: "App",
            productType: .application,
            buildSettings: [
                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
                "ENVIRONMENT_VARIABLES": ["TEST_VAR": "test_value"],
            ]
        )

        let mapped = try mapper.map(pbxTarget: target, projectProvider: mockProvider)
        #expect(mapped.environmentVariables["TEST_VAR"]?.value == "test_value")
        #expect(mapped.environmentVariables["TEST_VAR"]?.isEnabled == true)
    }

    @Test("Maps a target with launch arguments")
    func testMapTargetWithLaunchArguments() throws {
        let target = createTarget(
            name: "App",
            productType: .application,
            buildSettings: [
                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
                "LAUNCH_ARGUMENTS": ["-debug", "--verbose"],
            ]
        )

        let mapped = try mapper.map(pbxTarget: target, projectProvider: mockProvider)
        let expected = [
            LaunchArgument(name: "-debug", isEnabled: true),
            LaunchArgument(name: "--verbose", isEnabled: true),
        ]
        #expect(mapped.launchArguments == expected)
    }

    @Test("Maps a target with source files")
    func testMapTargetWithSourceFiles() throws {
        let pbxProj = mockProvider.pbxProj
        let sourceFile = try PBXFileReference.test(
            path: "ViewController.swift",
            lastKnownFileType: "sourcecode.swift"
        ).add(to: pbxProj).addToMainGroup(in: pbxProj)

        let buildFile = PBXBuildFile(file: sourceFile).add(to: pbxProj)
        let sourcesPhase = PBXSourcesBuildPhase(files: [buildFile]).add(to: pbxProj)

        let target = createTarget(
            name: "App",
            productType: .application,
            buildPhases: [sourcesPhase],
            buildSettings: ["PRODUCT_BUNDLE_IDENTIFIER": "com.example.app"]
        )

        let mapped = try mapper.map(pbxTarget: target, projectProvider: mockProvider)
        #expect(mapped.sources.count == 1)
        #expect(mapped.sources[0].path.basename == "ViewController.swift")
    }

    @Test("Maps a target with metadata tags")
    func testMapTargetWithMetadata() throws {
        let target = createTarget(
            name: "App",
            productType: .application,
            buildSettings: [
                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
                "TAGS": "tag1, tag2, tag3",
            ]
        )

        let mapped = try mapper.map(pbxTarget: target, projectProvider: mockProvider)
        #expect(mapped.metadata.tags == Set(["tag1", "tag2", "tag3"]))
    }

    @Test("Maps entitlements when CODE_SIGN_ENTITLEMENTS is set")
    func testMapEntitlements() async throws {
        // Create a temporary directory for the test.
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            // Cleanup the temporary directory after the test.
            try? FileManager.default.removeItem(at: tempDir)
        }

        // Update the mockProvider to reflect the temporary directory as the source directory.
        let sourceDirectory = try AbsolutePath(validating: tempDir.path)
        let provider = MockProjectProvider(
            sourceDirectory: sourceDirectory.pathString,
            pbxProj: mockProvider.pbxProj
        )

        // Create a mock entitlements file.
        let entitlementsPath = sourceDirectory.appending(component: "App.entitlements")
        try "{}".write(toFile: entitlementsPath.pathString, atomically: true, encoding: .utf8)

        // Create build configurations with CODE_SIGN_ENTITLEMENTS set.
        let debugConfig = XCBuildConfiguration(
            name: "Debug",
            buildSettings: [
                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
                "CODE_SIGN_ENTITLEMENTS": "App.entitlements"
            ]
        )
        let releaseConfig = XCBuildConfiguration(
            name: "Release",
            buildSettings: [
                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
                "CODE_SIGN_ENTITLEMENTS": "App.entitlements"
            ]
        )

        let configList = XCConfigurationList(
            buildConfigurations: [debugConfig, releaseConfig],
            defaultConfigurationName: "Release"
        )

        provider.pbxProj.add(object: debugConfig)
        provider.pbxProj.add(object: releaseConfig)
        provider.pbxProj.add(object: configList)

        let target = PBXNativeTarget.test(
            name: "App",
            buildConfigurationList: configList,
            buildPhases: [],
            productType: .application
        )

        let mapped = try mapper.map(pbxTarget: target, projectProvider: provider)
        #expect(mapped.entitlements == .file(path: entitlementsPath))
    }


    @Test("Throws noProjectsFound when pbxProj has no projects")
    func testMapTarget_noProjectsFound() throws {
        // Remove all projects from pbxProj
        var mockProvider = MockProjectProvider(pbxProj: PBXProj())
        let mapper = PBXTargetMapper()
        let target = PBXNativeTarget.test()
        mockProvider.xcodeProj = XcodeProj(workspace: XCWorkspace(), pbxproj: PBXProj())

        #expect(throws: TargetMappingError.noProjectsFound(path: mockProvider.xcodeProjPath.pathString)) {
            _ = try mapper.mapAdditionalFiles(from: target, projectProvider: mockProvider)
        }

        #expect {
            _ = try mapper.mapAdditionalFiles(from: target, projectProvider: mockProvider)
        } throws: { error in
            return error.localizedDescription == "No project was found at: /tmp/TestProject.xcodproj."
        }
    }

    @Test("Throws missingFilesGroup when mainGroup is nil")
    func testMapTarget_missingFilesGroup() throws {
        let mapper = PBXTargetMapper()

        var mockProvider = MockProjectProvider(pbxProj: PBXProj())
        let target = createTarget(
            name: "App",
            productType: .application,
            buildSettings: ["PRODUCT_BUNDLE_IDENTIFIER": "com.example.app"]
        )
        mockProvider.xcodeProj = XcodeProj(workspace: XCWorkspace(), pbxproj: PBXProj())

        #expect(throws: TargetMappingError.missingFilesGroup(targetName: "App")) {
            _ = try mapper.extractFilesGroup(from: target, projectProvider: mockProvider)
        }

        #expect {
            _ = try mapper.extractFilesGroup(from: target, projectProvider: mockProvider)
        } throws: { error in
            return error.localizedDescription == "The files group is missing for the target 'App'."
        }
    }

    @Test("Parses a valid Info.plist successfully")
    func testMapTarget_validPlist() throws {
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        let srcPath = try AbsolutePath(validating: tempDirectory.path)

        let relativePath = try RelativePath(validating: "Info.plist")
        let plistPath = srcPath.appending(relativePath)

        let plistContent: [String: Any] = [
            "CFBundleIdentifier": "com.example.app",
            "CFBundleName": "ExampleApp",
            "CFVersion": 1.4
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plistContent, format: .xml, options: 0)
        try data.write(to: URL(fileURLWithPath: plistPath.pathString))

        let target = createTarget(
            name: "App",
            productType: .application,
            buildSettings: [
                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
                "INFOPLIST_FILE": relativePath.pathString
            ]
        )
        var mockProvider = MockProjectProvider(pbxProj: PBXProj())
        mockProvider.sourceDirectory = srcPath
        mockProvider.xcodeProj = XcodeProj(workspace: XCWorkspace(), pbxproj: PBXProj())

        let mapper = PBXTargetMapper()

        let infoPlist = try mapper.extractInfoPlist(from: target, projectProvider: mockProvider)

        #expect({
            switch infoPlist {
            case let .dictionary(dict):
                return dict["CFBundleIdentifier"] == .string("com.example.app")
                    && dict["CFBundleName"] == .string("ExampleApp")
            default:
                return false
            }
        }() == true)
    }

    @Test("Throws invalidPlist when Info.plist cannot be parsed")
    func testMapTarget_invalidPlist() throws {
        // Create a fake plist that is not actually a plist
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        let srcPath = try AbsolutePath(validating: tempDirectory.path)

        let relativePath = try RelativePath(validating: "Invalid.plist")
        let invalidPlistPath = srcPath.appending(relativePath)

        try "Not a plist".write(toFile: invalidPlistPath.pathString, atomically: true, encoding: .utf8)

        let target = createTarget(
            name: "App",
            productType: .application,
            buildSettings: [
                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
                "INFOPLIST_FILE": relativePath.pathString
            ]
        )
        var mockProvider = MockProjectProvider(pbxProj: PBXProj())
        mockProvider.sourceDirectory = srcPath
        mockProvider.xcodeProj = XcodeProj(workspace: XCWorkspace(), pbxproj: PBXProj())

        let mapper = PBXTargetMapper()

        #expect {
            _ = try mapper.extractInfoPlist(from: target, projectProvider: mockProvider)
        } throws: { error in
            return error.localizedDescription == "Failed to read a valid plist dictionary from file at: \(invalidPlistPath.pathString)."
        }
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

        let target = PBXNativeTarget.test(
            name: name,
            buildConfigurationList: configurationList,
            buildRules: [],
            buildPhases: buildPhases,
            dependencies: dependencies,
            productType: productType
        )

        return target
    }
}
