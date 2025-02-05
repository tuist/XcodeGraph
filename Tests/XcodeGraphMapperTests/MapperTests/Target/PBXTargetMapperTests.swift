import FileSystem
import Foundation
import Path
import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeGraphMapper

@Suite
struct PBXTargetMapperTests {
    @Test("Maps a basic target with a product bundle identifier")
    func testMapBasicTarget() async throws {
        // Given
        let xcodeProj = try await XcodeProj.test()
        let target = createTarget(
            name: "App",
            xcodeProj: xcodeProj,
            productType: .application,
            buildSettings: ["PRODUCT_BUNDLE_IDENTIFIER": "com.example.app"]
        )
        try xcodeProj.mainPBXProject().targets.append(target)
        try xcodeProj.write(path: xcodeProj.path!)

        // When
        let mapper = PBXTargetMapper()

        let mapped = try await mapper.map(pbxTarget: target, xcodeProj: xcodeProj)

        // Then
        #expect(mapped.name == "App")
        #expect(mapped.product == .app)
        #expect(mapped.productName == "App")
        #expect(mapped.bundleId == "com.example.app")
    }

    @Test("Throws an error if the target is missing a bundle identifier")
    func testMapTargetWithMissingBundleId() async throws {
        // Given
        let xcodeProj = try await XcodeProj.test()

        let target = createTarget(
            name: "App",
            xcodeProj: xcodeProj,
            productType: .application,
            buildSettings: [:]
        )
        let mapper = PBXTargetMapper()

        // When / Then
        await #expect(throws: PBXTargetMappingError.missingBundleIdentifier(targetName: "App")) {
            _ = try await mapper.map(pbxTarget: target, xcodeProj: xcodeProj)
        }
    }

    @Test("Maps a target with environment variables")
    func testMapTargetWithEnvironmentVariables() async throws {
        // Given
        let xcodeProj = try await XcodeProj.test()
        let target = createTarget(
            name: "App",
            xcodeProj: xcodeProj,
            productType: .application,
            buildSettings: [
                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
                "ENVIRONMENT_VARIABLES": ["TEST_VAR": "test_value"],
            ]
        )
        let mapper = PBXTargetMapper()

        // When
        let mapped = try await mapper.map(pbxTarget: target, xcodeProj: xcodeProj)

        // Then
        #expect(mapped.environmentVariables["TEST_VAR"]?.value == "test_value")
        #expect(mapped.environmentVariables["TEST_VAR"]?.isEnabled == true)
    }

    @Test("Maps a target with launch arguments")
    func testMapTargetWithLaunchArguments() async throws {
        // Given
        let xcodeProj = try await XcodeProj.test()

        let target = createTarget(
            name: "App",
            xcodeProj: xcodeProj,
            productType: .application,
            buildSettings: [
                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
                "LAUNCH_ARGUMENTS": ["-debug", "--verbose"],
            ]
        )
        let mapper = PBXTargetMapper()

        // When
        let mapped = try await mapper.map(pbxTarget: target, xcodeProj: xcodeProj)

        // Then
        let expected = [
            LaunchArgument(name: "-debug", isEnabled: true),
            LaunchArgument(name: "--verbose", isEnabled: true),
        ]
        #expect(mapped.launchArguments == expected)
    }

    @Test("Maps a target with source files")
    func testMapTargetWithSourceFiles() async throws {
        // Given
        let xcodeProj = try await XcodeProj.test()

        let pbxProj = xcodeProj.pbxproj
        let sourceFile = try PBXFileReference.test(
            path: "ViewController.swift",
            lastKnownFileType: "sourcecode.swift"
        )
        .add(to: pbxProj)
        .addToMainGroup(in: pbxProj)

        let buildFile = PBXBuildFile(file: sourceFile).add(to: pbxProj)
        let sourcesPhase = PBXSourcesBuildPhase(files: [buildFile]).add(to: pbxProj)

        let target = createTarget(
            name: "App",
            xcodeProj: xcodeProj,
            productType: .application,
            buildPhases: [sourcesPhase],
            buildSettings: ["PRODUCT_BUNDLE_IDENTIFIER": "com.example.app"]
        )
        let mapper = PBXTargetMapper()

        // When
        let mapped = try await mapper.map(pbxTarget: target, xcodeProj: xcodeProj)

        // Then
        #expect(mapped.sources.count == 1)
        #expect(mapped.sources[0].path.basename == "ViewController.swift")
    }

    @Test("Maps a target with metadata tags")
    func testMapTargetWithMetadata() async throws {
        // Given
        let xcodeProj = try await XcodeProj.test()
        let target = createTarget(
            name: "App",
            xcodeProj: xcodeProj,
            productType: .application,
            buildSettings: [
                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
                "TAGS": "tag1, tag2, tag3",
            ]
        )
        let mapper = PBXTargetMapper()

        // When
        let mapped = try await mapper.map(pbxTarget: target, xcodeProj: xcodeProj)

        // Then
        #expect(mapped.metadata.tags == Set(["tag1", "tag2", "tag3"]))
    }

    @Test("Maps entitlements when CODE_SIGN_ENTITLEMENTS is set")
    func testMapEntitlements() async throws {
        // Given

        let xcodeProj = try await XcodeProj.test()
        let sourceDirectory = xcodeProj.srcPath
        let entitlementsPath = sourceDirectory.appending(component: "App.entitlements")

        let buildSettings: BuildSettings = [
            "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
            "CODE_SIGN_ENTITLEMENTS": "App.entitlements",
        ]

        let debugConfig = XCBuildConfiguration(
            name: "Debug",
            buildSettings: buildSettings
        )

        let configurationList = XCConfigurationList(
            buildConfigurations: [debugConfig],
            defaultConfigurationName: "Debug"
        )

        xcodeProj.pbxproj.add(object: debugConfig)
        xcodeProj.pbxproj.add(object: configurationList)

        let sourceFile = try PBXFileReference.test(
            path: "ViewController.swift",
            lastKnownFileType: "sourcecode.swift"
        ).add(to: xcodeProj.pbxproj).addToMainGroup(in: xcodeProj.pbxproj)

        let buildFile = PBXBuildFile(file: sourceFile).add(to: xcodeProj.pbxproj).add(to: xcodeProj.pbxproj)
        let sourcesPhase = PBXSourcesBuildPhase(files: [buildFile]).add(to: xcodeProj.pbxproj).add(to: xcodeProj.pbxproj)

        // Add targets to each project
        let target = try PBXNativeTarget.test(
            name: "ATarget",
            buildConfigurationList: configurationList,
            buildPhases: [sourcesPhase],
            productType: .framework
        )
        .add(to: xcodeProj.pbxproj)
        .add(to: xcodeProj.pbxproj.rootObject)

        let mapper = PBXTargetMapper()

        // When
        let mapped = try await mapper.map(pbxTarget: target, xcodeProj: xcodeProj)

        // Then
        #expect(mapped.entitlements == .file(
            path: entitlementsPath,
            configuration: BuildConfiguration(name: "Debug", variant: .debug)
        ))
    }

    @Test("Throws noProjectsFound when pbxProj has no projects")
    func testMapTarget_noProjectsFound() async throws {
        // Given
        let xcodeProj = try await XcodeProj.test()
        let target = PBXNativeTarget.test()

        try xcodeProj.mainPBXProject().targets.append(target)
        try xcodeProj.write(path: xcodeProj.path!)

        let mapper = PBXTargetMapper()

        // When / Then

        do {
            _ = try await mapper.map(pbxTarget: target, xcodeProj: xcodeProj)
            Issue.record("Should throw an error")
        } catch {
            let err = try #require(error as? PBXObjectError)
            #expect(err.description == "The PBXObjects instance has been released before saving.")
        }
    }

    @Test("Parses a valid Info.plist successfully")
    func testMapTarget_validPlist() async throws {
        // Given

        let xcodeProj = try await XcodeProj.test()
        let srcPath = xcodeProj.srcPath
        let relativePath = try RelativePath(validating: "Info.plist")
        let plistPath = srcPath.appending(relativePath)

        let plistContent: [String: Any] = [
            "CFBundleIdentifier": "com.example.app",
            "CFBundleName": "ExampleApp",
            "CFVersion": 1.4,
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plistContent, format: .xml, options: 0)
        try data.write(to: URL(fileURLWithPath: plistPath.pathString))

        let target = createTarget(
            name: "App",
            xcodeProj: xcodeProj,
            productType: .application,
            buildSettings: [
                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
                "INFOPLIST_FILE": relativePath.pathString,
            ]
        )

        try xcodeProj.write(path: xcodeProj.path!)
        let mapper = PBXTargetMapper()

        // When
        let mapped = try await mapper.map(pbxTarget: target, xcodeProj: xcodeProj)

        // Then
        #expect({
            switch mapped.infoPlist {
            case let .dictionary(dict, _):

                return dict["CFBundleIdentifier"] == "com.example.app"
                    && dict["CFBundleName"] == "ExampleApp"
            default:
                return false
            }
        }() == true)
    }

    @Test("Throws invalidPlist when Info.plist cannot be parsed")
    func testMapTarget_invalidPlist() async throws {
        // Given
        let xcodeProj = try await XcodeProj.test()
        let srcPath = xcodeProj.srcPath
        let relativePath = try RelativePath(validating: "Invalid.plist")
        let invalidPlistPath = srcPath.appending(relativePath)
        try await FileSystem().writeText("Invalid Plist", at: invalidPlistPath)

        let target = createTarget(
            name: "App",
            xcodeProj: xcodeProj,
            productType: .application,
            buildSettings: [
                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
                "INFOPLIST_FILE": relativePath.pathString,
            ]
        )
        try xcodeProj.write(path: xcodeProj.path!)

        let mapper = PBXTargetMapper()

        // When / Then
        await #expect {
            _ = try await mapper.map(pbxTarget: target, xcodeProj: xcodeProj)
        } throws: { error in
            error.localizedDescription
                == "Failed to read a valid plist dictionary from file at: \(invalidPlistPath.pathString)."
        }
    }

    // MARK: - Helper Methods

    private func createTarget(
        name: String,
        xcodeProj: XcodeProj,
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

        xcodeProj.pbxproj.add(object: debugConfig)
        xcodeProj.pbxproj.add(object: releaseConfig)
        xcodeProj.pbxproj.add(object: configurationList)

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
