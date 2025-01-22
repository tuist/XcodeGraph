import Path
import Testing
import XcodeProj
@testable import XcodeGraph
@testable import XcodeProjMapper

@Suite
struct TargetDependencyExtensionsTests {
    let sourceDirectory = try! AbsolutePath(validating: "/tmp/TestProject")

    // A dummy target map for .project dependencies
    let allTargetsMap: [String: Target] = [
        "MyProjectTarget": Target.test(name: "MyProjectTarget", product: .framework),
        "MyProjectDynamicLibrary": Target.test(name: "MyProjectDynamicLibrary", product: .dynamicLibrary),
    ]

    @Test("Resolves a target dependency into a target graph dependency")
    func testTargetGraphDependency_Target() throws {
        let dependency = TargetDependency.target(name: "App", status: .required, condition: nil)
        let graphDep = try dependency.graphDependency(
            sourceDirectory: sourceDirectory,
            allTargetsMap: allTargetsMap
        )
        #expect(graphDep == .target(name: "App", path: sourceDirectory, status: .required))
    }

    @Test("Resolves a project-based framework dependency to a dynamic framework in the graph")
    func testTargetGraphDependencyFramework_Project() throws {
        let dependency = TargetDependency.project(
            target: "MyProjectTarget",
            path: sourceDirectory,
            status: .required,
            condition: nil
        )

        let graphDep = try dependency.graphDependency(
            sourceDirectory: sourceDirectory,
            allTargetsMap: allTargetsMap
        )

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
    func testTargetGraphDependencyLibrary_Project() throws {
        let dependency = TargetDependency.project(
            target: "MyProjectDynamicLibrary",
            path: sourceDirectory,
            status: .required,
            condition: nil
        )
        let graphDep = try dependency.graphDependency(
            sourceDirectory: sourceDirectory,
            allTargetsMap: allTargetsMap
        )

        switch graphDep {
        case let .library(path, _, linking, archs, _):
            #expect(path == sourceDirectory.appending(component: "libMyProjectDynamicLibrary.dylib"))
            #expect(linking == .dynamic)
            #expect(archs.isEmpty == true)
        default:
            Issue.record("Expected a library graph dependency.")
        }
    }

    @Test("Resolves a framework file dependency into a dynamic framework graph dependency")
    func testTargetGraphDependency_Framework() throws {
        let frameworkPath = sourceDirectory.appending(component: "MyFramework.framework")
        let dependency = TargetDependency.framework(path: frameworkPath, status: .required, condition: nil)
        let graphDep = try dependency.graphDependency(sourceDirectory: sourceDirectory, allTargetsMap: [:])

        #expect({
            switch graphDep {
            case let .framework(path, binaryPath, _, _, linking, archs, status):
                return path == frameworkPath
                    && binaryPath == frameworkPath.appending(component: "MyFramework")
                    && linking == .dynamic && archs.isEmpty && status == .required
            default:
                return false
            }
        }() == true)
    }

    @Test("Resolves an XCFramework dependency to the correct .xcframework graph dependency")
    func testTargetGraphDependency_XCFramework() throws {
        let xcframeworkPath = sourceDirectory.appending(component: "MyXCFramework.xcframework")
        let dependency = TargetDependency.xcframework(path: xcframeworkPath, status: .required, condition: nil)
        let graphDep = try dependency.graphDependency(sourceDirectory: sourceDirectory, allTargetsMap: [:])

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
    func testTargetGraphDependency_Library() throws {
        let libPath = sourceDirectory.appending(component: "libMyLib.a")
        let headersPath = sourceDirectory.appending(component: "include")
        let dependency = TargetDependency.library(path: libPath, publicHeaders: headersPath, swiftModuleMap: nil, condition: nil)

        let graphDep = try dependency.graphDependency(sourceDirectory: sourceDirectory, allTargetsMap: [:])

        #expect({
            switch graphDep {
            case let .library(path, publicHeaders, linking, archs, swiftModuleMap):
                return path == libPath && publicHeaders == headersPath && linking == .static
                    && archs.isEmpty && swiftModuleMap == nil
            default:
                return false
            }
        }() == true)
    }

    @Test("Resolves a package product dependency to a package product graph dependency")
    func testTargetGraphDependency_Package() throws {
        let dependency = TargetDependency.package(product: "MyPackageProduct", type: .runtime, condition: nil)
        let graphDep = try dependency.graphDependency(sourceDirectory: sourceDirectory, allTargetsMap: [:])
        #expect(graphDep == .packageProduct(path: sourceDirectory, product: "MyPackageProduct", type: .runtime))
    }

    @Test("Resolves an SDK dependency to the correct SDK graph dependency")
    func testTargetGraphDependency_SDK() throws {
        let dependency = TargetDependency.sdk(name: "MySDK", status: .optional, condition: nil)
        let graphDep = try dependency.graphDependency(sourceDirectory: sourceDirectory, allTargetsMap: [:])

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
    func testTargetGraphDependency_XCTest() throws {
        let dependency = TargetDependency.xctest
        let graphDep = try dependency.graphDependency(sourceDirectory: sourceDirectory, allTargetsMap: [:])

        #expect({
            switch graphDep {
            case let .xcframework(info):
                return info.path == sourceDirectory && info.linking == .dynamic && info.status == .required
            default:
                return false
            }
        }() == true)
    }

    @Test("Throws a MappingError when a project target does not exist in allTargetsMap")
    func testMapProjectGraphDependency_TargetNotFound() throws {
        let dependency = TargetDependency.project(
            target: "NonExistentTarget",
            path: sourceDirectory,
            status: .required,
            condition: nil
        )

        do {
            _ = try dependency.graphDependency(sourceDirectory: sourceDirectory, allTargetsMap: [:])
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
