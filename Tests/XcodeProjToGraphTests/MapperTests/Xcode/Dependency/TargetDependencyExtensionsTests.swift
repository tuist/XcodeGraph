import Path
import Testing
import XcodeGraph
import XcodeProj

@testable import TestSupport
@testable import XcodeProjToGraph

struct TargetDependencyExtensionsTests {
  let sourceDirectory = try! AbsolutePath.resolvePath("/tmp/TestProject")

  // A dummy global target map for .project dependencies
  let allTargetsMap: [String: Target] = [
    "MyProjectTarget": Target.test(
      name: "MyProjectTarget",
      product: .framework
    ),
    "MyProjectDynamicLibrary": Target.test(
      name: "MyProjectDynamicLibrary",
      product: .dynamicLibrary
    ),
  ]

  @Test func testTargetGraphDependency_Target() async throws {
    let dependency = TargetDependency.target(name: "App", status: .required, condition: nil)
    let graphDep = try await dependency.graphDependency(
      sourceDirectory: sourceDirectory,
      allTargetsMap: allTargetsMap
    )
    #expect(graphDep == .target(name: "App", path: sourceDirectory, status: .required))
  }

  @Test func testTargetGraphDependencyFramework_Project() async throws {
    let dependency = TargetDependency.project(
      target: "MyProjectTarget",
      path: sourceDirectory,
      status: .required,
      condition: nil
    )
    let graphDep = try await dependency.graphDependency(
      sourceDirectory: sourceDirectory,
      allTargetsMap: allTargetsMap
    )

    #expect(
      ({
        switch graphDep {
        case let .framework(path, binaryPath, _, _, linking, archs, status):
          return path == sourceDirectory
            && binaryPath == sourceDirectory.appending(component: "MyProjectTarget.framework")
            && linking == .dynamic && archs.isEmpty && status == .required
        default:
          return false
        }
      })() != false)
  }

  @Test func testTargetGraphDependencyLibrary_Project() async throws {
    let dependency = TargetDependency.project(
      target: "MyProjectDynamicLibrary",
      path: sourceDirectory,
      status: .required,
      condition: nil
    )
    let graphDep = try await dependency.graphDependency(
      sourceDirectory: sourceDirectory,
      allTargetsMap: allTargetsMap
    )

    switch graphDep {
    case let .library(path, _, linking, _, _):
      #expect(
        path.pathString
          == sourceDirectory.appending(component: "libMyProjectDynamicLibrary.dylib").pathString)
      #expect(linking == .dynamic)
    default:
      Issue.record()
    }
  }

  @Test func testTargetGraphDependency_Framework() async throws {
    let frameworkPath = sourceDirectory.appending(component: "MyFramework.framework")
    let dependency = TargetDependency.framework(
      path: frameworkPath, status: .required, condition: nil)
    let graphDep = try await dependency.graphDependency(
      sourceDirectory: sourceDirectory,
      allTargetsMap: [:]
    )

    #expect(
      ({
        switch graphDep {
        case let .framework(path, binaryPath, _, _, linking, archs, status):
          return path == frameworkPath
            && binaryPath == frameworkPath.appending(component: "MyFramework")
            && linking == .dynamic && archs.isEmpty && status == .required
        default:
          return false
        }
      })() != false)
  }

  @Test func testTargetGraphDependency_XCFramework() async throws {
    let xcframeworkPath = sourceDirectory.appending(component: "MyXCFramework.xcframework")
    let dependency = TargetDependency.xcframework(
      path: xcframeworkPath, status: .required, condition: nil)
    let graphDep = try await dependency.graphDependency(
      sourceDirectory: sourceDirectory,
      allTargetsMap: [:]
    )

    #expect(
      ({
        switch graphDep {
        case let .xcframework(info):
          return info.path == xcframeworkPath && info.linking == .dynamic
            && info.status == .required
        default:
          return false
        }
      })() != false)
  }

  @Test func testTargetGraphDependency_Library() async throws {
    let libPath = sourceDirectory.appending(component: "libMyLib.a")
    let headersPath = sourceDirectory.appending(component: "include")
    let dependency = TargetDependency.library(
      path: libPath,
      publicHeaders: headersPath,
      swiftModuleMap: nil,
      condition: nil
    )
    let graphDep = try await dependency.graphDependency(
      sourceDirectory: sourceDirectory,
      allTargetsMap: [:]
    )

    #expect(
      ({
        switch graphDep {
        case let .library(path, publicHeaders, linking, archs, swiftModuleMap):
          return path == libPath && publicHeaders == headersPath && linking == .static
            && archs.isEmpty && swiftModuleMap == nil
        default:
          return false
        }
      })() != false)
  }

  @Test func testTargetGraphDependency_Package() async throws {
    let dependency = TargetDependency.package(
      product: "MyPackageProduct", type: .runtime, condition: nil)
    let graphDep = try await dependency.graphDependency(
      sourceDirectory: sourceDirectory,
      allTargetsMap: [:]
    )

    #expect(
      graphDep
        == .packageProduct(path: sourceDirectory, product: "MyPackageProduct", type: .runtime))
  }

  @Test func testTargetGraphDependency_SDK() async throws {
    let dependency = TargetDependency.sdk(name: "MySDK", status: .optional, condition: nil)
    let graphDep = try await dependency.graphDependency(
      sourceDirectory: sourceDirectory,
      allTargetsMap: [:]
    )

    #expect(
      ({
        switch graphDep {
        case let .sdk(name, path, status, source):
          return name == "MySDK" && path == sourceDirectory && status == .optional
            && source == .developer
        default:
          return false
        }
      })() != false)
  }

  @Test func testTargetGraphDependency_XCTest() async throws {
    let dependency = TargetDependency.xctest
    let graphDep = try await dependency.graphDependency(
      sourceDirectory: sourceDirectory,
      allTargetsMap: [:]
    )

    #expect(
      ({
        switch graphDep {
        case let .xcframework(info):
          return info.path == sourceDirectory && info.linking == .dynamic
            && info.status == .required
        default:
          return false
        }
      })() != false)
  }

  @Test func testMapProjectGraphDependency_TargetNotFound() async throws {
    let dependency = TargetDependency.project(
      target: "NonExistentTarget",
      path: sourceDirectory,
      status: .required,
      condition: nil
    )

    do {
      _ = try await dependency.graphDependency(sourceDirectory: sourceDirectory, allTargetsMap: [:])
      Issue.record("Expected to throw MappingError.targetNotFound")
    } catch let error as MappingError {
      switch error {
      case .targetNotFound(let targetName, let path):
        #expect(targetName == "NonExistentTarget")
        #expect(path == sourceDirectory)
      default:
        Issue.record("Unexpected MappingError: \(error)")
      }
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}
