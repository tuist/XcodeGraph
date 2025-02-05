import Path
import Testing
import XcodeMetadata
import XcodeProj
@testable import XcodeGraph
@testable import XcodeGraphMapper

@Suite
struct TargetDependencyExtensionsTests {
    let sourceDirectory = AssertionsTesting.fixturePath()
    let target = Target.test(platform: .iOS)

    // A dummy target map for .project dependencies
    let allTargetsMap: [String: Target] = [
        "StaticLibrary": Target.test(name: "libStaticLibrary", product: .staticLibrary),
        "MyProjectTarget": Target.test(name: "MyProjectTarget", product: .framework),
        "MyProjectDynamicLibrary": Target.test(name: "MyProjectDynamicLibrary", product: .dynamicLibrary),
    ]

    @Test("Resolves a target dependency into a target graph dependency")
    func testTargetGraphDependency_Target() async throws {
        // Given
        let dependency = TargetDependency.target(name: "App", status: .required, condition: nil)

        // When
        let graphDep = try await dependency.graphDependency(
            sourceDirectory: sourceDirectory,
            allTargetsMap: allTargetsMap,
            target: target
        )

        // Then
        #expect(graphDep == .target(name: "App", path: sourceDirectory, status: .required))
    }

    @Test("Resolves a project-based framework dependency to a dynamic framework in the graph")
    func testTargetGraphDependencyFramework_Project() async throws {
        // Given
        let dependency = TargetDependency.project(
            target: "MyProjectTarget",
            path: sourceDirectory,
            status: .required,
            condition: nil
        )

        // When
        let graphDep = try await dependency.graphDependency(
            sourceDirectory: sourceDirectory,
            allTargetsMap: allTargetsMap,
            target: target
        )

        // Then
        #expect({
            switch graphDep {
            case let .framework(path, binaryPath, _, _, linking, archs, status):
                return path == sourceDirectory
                    && binaryPath == sourceDirectory.appending(component: "MyProjectTarget.framework")
                    && linking == .dynamic && archs.isEmpty && status == .required
            default:
                return false
            }
        }() == true)
    }

    @Test("Resolves a project-based dynamic library dependency correctly")
    func testTargetGraphDependencyLibrary_Project() async throws {
        // Given
        let libraryPath = AssertionsTesting.fixturePath(path: try RelativePath(validating: "libStaticLibrary.a"))

        let dependency = TargetDependency.project(
            target: "StaticLibrary",
            path: sourceDirectory,
            status: .required,
            condition: nil
        )

        // When
        let graphDep = try await dependency.graphDependency(
            sourceDirectory: sourceDirectory,
            allTargetsMap: allTargetsMap,
            target: target
        )

        let expected = GraphDependency.library(
            path: libraryPath,
            publicHeaders: libraryPath.parentDirectory.appending(component: "include"),
            linking: .static,
            architectures: [],
            swiftModuleMap: nil
        )

        // Then
        #expect(expected == graphDep)
    }

    @Test("Resolves a framework file dependency into a dynamic framework graph dependency")
    func testTargetGraphDependency_Framework() async throws {
        // Given
        let frameworkPath = sourceDirectory.appending(component: "xpm.framework")
        let dependency = TargetDependency.framework(path: frameworkPath, status: .required, condition: nil)

        // When
        let graphDep = try await dependency.graphDependency(
            sourceDirectory: sourceDirectory,
            allTargetsMap: allTargetsMap,
            target: target
        )
        let expectedBinaryPath = frameworkPath.appending(component: frameworkPath.basenameWithoutExt)
        let expectedDsymPath = frameworkPath.parentDirectory.appending(component: "xpm.framework.dSYM")
        let expected = GraphDependency.framework(
            path: frameworkPath,
            binaryPath: expectedBinaryPath,
            dsymPath: expectedDsymPath,
            bcsymbolmapPaths: [],
            linking: .dynamic,
            architectures: [.x8664, .arm64],
            status: .required
        )

        // Then
        #expect(expected == graphDep)
    }

    @Test("Resolves an XCFramework dependency to the correct .xcframework graph dependency")
    func testTargetGraphDependency_XCFramework() async throws {
        // Given
        let xcframeworkPath = sourceDirectory.appending(component: "MyFramework.xcframework")
        let dependency = TargetDependency.xcframework(path: xcframeworkPath, status: .required, condition: nil)

        // When
        let graphDep = try await dependency.graphDependency(
            sourceDirectory: sourceDirectory,
            allTargetsMap: allTargetsMap,
            target: target
        )

        // Then
        #expect({
            switch graphDep {
            case let .xcframework(info):
                return info.path == xcframeworkPath && info.linking == .dynamic && info.status == .required
            default:
                return false
            }
        }() == true)
    }

    @Test("Resolves a static library dependency to a static library graph dependency")
    func testTargetGraphDependency_Library() async throws {
        // Given
        let libPath = sourceDirectory.appending(component: "libStaticLibrary.a")
        let headersPath = sourceDirectory.parentDirectory
        let dependency = TargetDependency.library(path: libPath, publicHeaders: headersPath, swiftModuleMap: nil, condition: nil)

        // When
        let graphDep = try await dependency.graphDependency(
            sourceDirectory: sourceDirectory,
            allTargetsMap: allTargetsMap,
            target: target
        )
        let expected = GraphDependency.library(
            path: libPath,
            publicHeaders: headersPath,
            linking: .static,
            architectures: [.x8664],
            swiftModuleMap: nil
        )

        // Then
        #expect(expected == graphDep)
    }

    @Test("Resolves a package product dependency to a package product graph dependency")
    func testTargetGraphDependency_Package() async throws {
        // Given
        let dependency = TargetDependency.package(product: "MyPackageProduct", type: .runtime, condition: nil)

        // When
        let graphDep = try await dependency.graphDependency(
            sourceDirectory: sourceDirectory,
            allTargetsMap: allTargetsMap,
            target: target
        )
        // Then
        #expect(graphDep == .packageProduct(path: sourceDirectory, product: "MyPackageProduct", type: .runtime))
    }

    @Test("Resolves an SDK dependency to the correct SDK graph dependency")
    func testTargetGraphDependency_SDK() async throws {
        // Given
        let dependency = TargetDependency.sdk(name: "MySDK", status: .optional, condition: nil)

        // When
        let graphDep = try await dependency.graphDependency(
            sourceDirectory: sourceDirectory,
            allTargetsMap: allTargetsMap,
            target: target
        )
        // Then
        #expect({
            switch graphDep {
            case let .sdk(name, path, status, source):
                return name == "MySDK" && path == sourceDirectory && status == .optional && source == .developer
            default:
                return false
            }
        }() == true)
    }

    @Test("Resolves an XCTest dependency to an XCFramework graph dependency")
    func testTargetGraphDependency_XCTest() async throws {
        // Given
        let dependency = TargetDependency.xctest
        let developerDirectory = try await DeveloperDirectoryProvider().developerDirectory()

        let srcPath = "/Platforms/iPhoneOS.platform/Developer/Library/Frameworks/XCTest.framework"
        let path = try AbsolutePath(
            validating: developerDirectory.pathString + srcPath
        )
        // When
        let graphDep = try await dependency.graphDependency(
            sourceDirectory: sourceDirectory,
            allTargetsMap: allTargetsMap,
            target: target
        )
        let expected = GraphDependency.framework(
            path: path,
            binaryPath: path.appending(component: "XCTest"),
            dsymPath: nil,
            bcsymbolmapPaths: [],
            linking: .dynamic,
            architectures: [.arm64, .arm64e],
            status: .required
        )

        // Then
        #expect(expected == graphDep)
    }

    @Test("Throws a MappingError when a project target does not exist in allTargetsMap")
    func testMapProjectGraphDependency_TargetNotFound() async throws {
        // Given
        let dependency = TargetDependency.project(
            target: "NonExistentTarget",
            path: sourceDirectory,
            status: .required,
            condition: nil
        )

        // When / Then
        do {
            _ = try await dependency.graphDependency(sourceDirectory: sourceDirectory, allTargetsMap: [:], target: target)
            Issue.record("Expected to throw TargetDependencyMappingError.targetNotFound")
        } catch let error as TargetDependencyMappingError {
            switch error {
            case let .targetNotFound(targetName, path):
                #expect(targetName == "NonExistentTarget")
                #expect(path == sourceDirectory)
            default:
                Issue.record("Unexpected TargetDependencyMappingError: \(error)")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
