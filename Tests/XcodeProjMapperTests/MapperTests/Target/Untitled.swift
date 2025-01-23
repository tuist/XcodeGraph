//import Foundation
//import Path
//import Testing
//import XcodeGraph
//import XcodeProj
//@testable import XcodeProjMapper
//
//@Suite
//struct PBXTargetMapperTests {
//    let mapper: TargetMapping
//
//    init() {
//        mapper = PBXTargetMapper()
//    }
//
//    @Test("Maps a basic target with a product bundle identifier")
//    func testMapBasicTarget() async throws {
//        // Given
//        let target = createTarget(
//            name: "App",
//            productType: .application,
//            buildSettings: ["PRODUCT_BUNDLE_IDENTIFIER": "com.example.app"]
//        )
//        let xcodeProj = XcodeProj.test(targets: [target])
//        xcodeProj.pbxproj.add(object: target)
//        try xcodeProj.write(path: xcodeProj.path!)
//
//        // When
//        let mapped = try await mapper.map(pbxTarget: target, xcodeProj: xcodeProj)
//
//        // Then
//        #expect(mapped.name == "App")
//        #expect(mapped.product == .app)
//        #expect(mapped.productName == "App")
//        #expect(mapped.bundleId == "com.example.app")
//    }
//
//    @Test("Throws an error if the target is missing a bundle identifier")
//    func testMapTargetWithMissingBundleId() async throws {
//        // Given
//        let xcodeProj = XcodeProj.test()
//
//        let target = createTarget(
//            name: "App",
//            productType: .application,
//            buildSettings: [:]
//        )
//
//        // When / Then
//        await #expect(throws: TargetMappingError.missingBundleIdentifier(targetName: "App")) {
//            _ = try await mapper.map(pbxTarget: target, xcodeProj: xcodeProj)
//        }
//    }
//
//    @Test("Maps a target with environment variables")
//    func testMapTargetWithEnvironmentVariables() async throws {
//        // Given
//        let xcodeProj = XcodeProj.test()
//        let target = createTarget(
//            name: "App",
//            productType: .application,
//            buildSettings: [
//                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
//                "ENVIRONMENT_VARIABLES": ["TEST_VAR": "test_value"],
//            ]
//        )
//
//        // When
//        let mapped = try await mapper.map(pbxTarget: target, xcodeProj: xcodeProj)
//
//        // Then
//        #expect(mapped.environmentVariables["TEST_VAR"]?.value == "test_value")
//        #expect(mapped.environmentVariables["TEST_VAR"]?.isEnabled == true)
//    }
//
//    @Test("Maps a target with launch arguments")
//    func testMapTargetWithLaunchArguments() async throws {
//        // Given
//        let xcodeProj = XcodeProj.test()
//
//        let target = createTarget(
//            name: "App",
//            productType: .application,
//            buildSettings: [
//                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
//                "LAUNCH_ARGUMENTS": ["-debug", "--verbose"],
//            ]
//        )
//
//        // When
//        let mapped = try await mapper.map(pbxTarget: target, xcodeProj: xcodeProj)
//
//        // Then
//        let expected = [
//            LaunchArgument(name: "-debug", isEnabled: true),
//            LaunchArgument(name: "--verbose", isEnabled: true),
//        ]
//        #expect(mapped.launchArguments == expected)
//    }
//
//    @Test("Maps a target with source files")
//    func testMapTargetWithSourceFiles() async throws {
//        // Given
//        let xcodeProj = XcodeProj.test()
//
//        let pbxProj = xcodeProj.pbxproj
//        let sourceFile = try PBXFileReference.test(
//            path: "ViewController.swift",
//            lastKnownFileType: "sourcecode.swift"
//        )
//        .add(to: pbxProj)
//        .addToMainGroup(in: pbxProj)
//
//        let buildFile = PBXBuildFile(file: sourceFile).add(to: pbxProj)
//        let sourcesPhase = PBXSourcesBuildPhase(files: [buildFile]).add(to: pbxProj)
//
//        let target = createTarget(
//            name: "App",
//            productType: .application,
//            buildPhases: [sourcesPhase],
//            buildSettings: ["PRODUCT_BUNDLE_IDENTIFIER": "com.example.app"]
//        )
//
//        // When
//        let mapped = try await mapper.map(pbxTarget: target, xcodeProj: xcodeProj)
//
//        // Then
//        #expect(mapped.sources.count == 1)
//        #expect(mapped.sources[0].path.basename == "ViewController.swift")
//    }
//
//    @Test("Maps a target with metadata tags")
//    func testMapTargetWithMetadata() async throws {
//        // Given
//        let xcodeProj = XcodeProj.test()
//        let target = createTarget(
//            name: "App",
//            productType: .application,
//            buildSettings: [
//                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
//                "TAGS": "tag1, tag2, tag3",
//            ]
//        )
//
//        // When
//        let mapped = try await mapper.map(pbxTarget: target, xcodeProj: xcodeProj)
//
//        // Then
//        #expect(mapped.metadata.tags == Set(["tag1", "tag2", "tag3"]))
//    }
//
//    @Test("Maps entitlements when CODE_SIGN_ENTITLEMENTS is set")
//    func testMapEntitlements() async throws {
//        // Given
//        let xcodeProj = XcodeProj.test()
//
//        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
//        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
//
//        defer {
//            try? FileManager.default.removeItem(at: tempDir)
//        }
//
//        let sourceDirectory = try AbsolutePath(validating: tempDir.path)
//        let xcodeproj = XcodeProj.test(
//            sourceDirectory: sourceDirectory.pathString
//        )
//
//        let entitlementsPath = sourceDirectory.appending(component: "App.entitlements")
//        try "{}".write(toFile: entitlementsPath.pathString, atomically: true, encoding: .utf8)
//
//        let debugConfig = XCBuildConfiguration(
//            name: "Debug",
//            buildSettings: [
//                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
//                "CODE_SIGN_ENTITLEMENTS": "App.entitlements",
//            ]
//        )
//        let releaseConfig = XCBuildConfiguration(
//            name: "Release",
//            buildSettings: [
//                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
//                "CODE_SIGN_ENTITLEMENTS": "App.entitlements",
//            ]
//        )
//        let configList = XCConfigurationList(
//            buildConfigurations: [debugConfig, releaseConfig],
//            defaultConfigurationName: "Debug"
//        )
//
//        xcodeproj.pbxproj.add(object: debugConfig)
//        xcodeproj.pbxproj.add(object: releaseConfig)
//        xcodeproj.pbxproj.add(object: configList)
//
//        let target = PBXNativeTarget.test(
//            name: "App",
//            buildConfigurationList: configList,
//            buildPhases: [],
//            productType: .application
//        )
//
//        // When
//        let mapped = try await mapper.map(pbxTarget: target, xcodeProj: xcodeProj)
//
//        // Then
//        #expect(mapped.entitlements == .file(
//            path: entitlementsPath,
//            configuration: BuildConfiguration(name: "Debug", variant: .debug)
//        ))
//    }
//
//    @Test("Throws noProjectsFound when pbxProj has no projects")
//    func testMapTarget_noProjectsFound() async throws {
//        // Given
//        let xcodeProj = XcodeProj(workspace: XCWorkspace(), pbxproj: PBXProj(), path: "/tmp/TestProject.xcodproj")
//        let mapper = PBXTargetMapper()
//        let target = PBXNativeTarget.test()
//
//        // When / Then
//        await #expect(throws: TargetMappingError.noProjectsFound(path: xcodeProj.projectPath.pathString)) {
//            _ = try await mapper.mapAdditionalFiles(from: target, xcodeProj: xcodeProj)
//        }
//
//        // Also confirm the error message
//        await #expect {
//            _ = try await mapper.mapAdditionalFiles(from: target, xcodeProj: xcodeProj)
//        } throws: { error in
//            error.localizedDescription == "No project was found at: /tmp/TestProject.xcodproj."
//        }
//    }
//
//    @Test("Throws missingFilesGroup when mainGroup is nil")
//    func testMapTarget_missingFilesGroup() async throws {
//        // Given
//
//        let mapper = PBXTargetMapper()
//        let xcodeProj = XcodeProj.test()
//
//        let target = createTarget(
//            name: "App",
//            productType: .application,
//            buildSettings: ["PRODUCT_BUNDLE_IDENTIFIER": "com.example.app"]
//        )
//
//        // When / Then
//        await #expect(throws: TargetMappingError.missingFilesGroup(targetName: "App")) {
//            _ = try await mapper.extractFilesGroup(from: target, xcodeProj: xcodeProj)
//        }
//
//        await #expect {
//            _ = try await mapper.extractFilesGroup(from: target, xcodeProj: xcodeProj)
//        } throws: { error in
//            error.localizedDescription == "The files group is missing for the target 'App'."
//        }
//    }
//
//    @Test("Parses a valid Info.plist successfully")
//    func testMapTarget_validPlist() async throws {
//        // Given
//
//        let xcodeProj = XcodeProj.test()
//        let srcPath = xcodeProj.srcPath
//        let relativePath = try RelativePath(validating: "Info.plist")
//        let plistPath = srcPath.appending(relativePath)
//
//        let plistContent: [String: Any] = [
//            "CFBundleIdentifier": "com.example.app",
//            "CFBundleName": "ExampleApp",
//            "CFVersion": 1.4,
//        ]
//        let data = try PropertyListSerialization.data(fromPropertyList: plistContent, format: .xml, options: 0)
//        try data.write(to: URL(fileURLWithPath: plistPath.pathString))
//
//        let target = createTarget(
//            name: "App",
//            productType: .application,
//            buildSettings: [
//                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
//                "INFOPLIST_FILE": relativePath.pathString,
//            ]
//        )
//
//        try xcodeProj.write(path: xcodeProj.path!)
//        let mapper = PBXTargetMapper()
//
//        // When
//        let infoPlist = try await mapper.extractInfoPlist(from: target, xcodeProj: xcodeProj)
//
//        // Then
//        #expect({
//            switch infoPlist {
//            case let .dictionary(dict, _):
//
//                return dict["CFBundleIdentifier"] == "com.example.app"
//                    && dict["CFBundleName"] == "ExampleApp"
//            default:
//                return false
//            }
//        }() == true)
//    }
//
//    @Test("Throws invalidPlist when Info.plist cannot be parsed")
//    func testMapTarget_invalidPlist() async throws {
//        // Given
//        let xcodeProj = XcodeProj.test()
//        let srcPath = xcodeProj.srcPath
//        let relativePath = try RelativePath(validating: "Invalid.plist")
//        let invalidPlistPath = srcPath.appending(relativePath)
//        try "Not a plist".write(toFile: invalidPlistPath.pathString, atomically: true, encoding: .utf8)
//
//        let target = createTarget(
//            name: "App",
//            productType: .application,
//            buildSettings: [
//                "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
//                "INFOPLIST_FILE": relativePath.pathString,
//            ]
//        )
//        try xcodeProj.write(path: xcodeProj.path!)
//
//        let mapper = PBXTargetMapper()
//
//        // When / Then
//        await #expect {
//            _ = try await mapper.extractInfoPlist(from: target, xcodeProj: xcodeProj)
//        } throws: { error in
//            error.localizedDescription
//                == "Failed to read a valid plist dictionary from file at: \(invalidPlistPath.pathString)."
//        }
//    }
//
//    // MARK: - Helper Methods
//
//    private func createTarget(
//        name: String,
//        productType: PBXProductType,
//        buildPhases: [PBXBuildPhase] = [],
//        buildSettings: [String: Any] = [:],
//        dependencies: [PBXTargetDependency] = []
//    ) -> PBXNativeTarget {
//        let xcodeproj = XcodeProj.test()
//        let debugConfig = XCBuildConfiguration(
//            name: "Debug",
//            buildSettings: buildSettings
//        )
//
//        let releaseConfig = XCBuildConfiguration(
//            name: "Release",
//            buildSettings: buildSettings
//        )
//
//        let configurationList = XCConfigurationList(
//            buildConfigurations: [debugConfig, releaseConfig],
//            defaultConfigurationName: "Release"
//        )
//
//        xcodeproj.pbxproj.add(object: debugConfig)
//        xcodeproj.pbxproj.add(object: releaseConfig)
//        xcodeproj.pbxproj.add(object: configurationList)
//
//        let target = PBXNativeTarget.test(
//            name: name,
//            buildConfigurationList: configurationList,
//            buildRules: [],
//            buildPhases: buildPhases,
//            dependencies: dependencies,
//            productType: productType
//        )
//
//        return target
//    }
//}
