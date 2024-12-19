 import Foundation
 import Path
 import XcodeGraph
 import XcodeProj
 import XcodeProjMapper


 import XCTest
 import Testing

 class PerformanceTests: XCTestCase {
    func testFullGraphParsingPerformance_iosAppLarge() throws {
        let path = try WorkspaceFixture.iosAppLarge.absolutePath()
        let parser = ProjectParser()
        measureAsync {
            _ = try parser.parse(at: path.pathString)
        }
    }

    func testFullGraphParsingPerformance_commandLineToolWithDynamicFramework() throws {
        let path = try WorkspaceFixture.commandLineToolWithDynamicFramework.absolutePath()
        let parser = ProjectParser()

        measureAsync {
            _ = try parser.parse(at: path.pathString)
        }
    }

    func testFullGraphParsingPerformance_iosWorkspaceWithMicrofeatureArchitectureStaticLinking() throws {
        let path = try WorkspaceFixture.iosWorkspaceWithMicrofeatureArchitectureStaticLinking.absolutePath()
        let parser = ProjectParser()

        measureAsync {
            _ = try parser.parse(at: path.pathString)
        }
    }

    func testFullGraphParsingPerformance_iosAppWithStaticLibraries() throws {
        let path = try WorkspaceFixture.iosAppWithStaticLibraries.absolutePath()
        let parser = ProjectParser()

        measureAsync {
            _ = try parser.parse(at: path.pathString)
        }
    }

    // Current PR 2 seconds
    // Sync 5 seconds
//    func testFullGraphParsingPerformance_tuist() throws {
//        let path = try WorkspaceFixture.tuist.absolutePath()
//        let parser = ProjectParser()
//
//        measureAsync {
//            _ = try parser.parse(at: path.pathString)
//        }
//    }
 }


 extension XCTestCase {
  func measureAsync(
    timeout: TimeInterval = 30.0,
    for block: @escaping () throws -> Void,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    measureMetrics(
        [.wallClockTime],
      automaticallyStartMeasuring: true
    ) {
      let expectation = expectation(description: "finished")
      Task { @MainActor in
        do {
          try block()
          expectation.fulfill()
        } catch {
          XCTFail(error.localizedDescription, file: file, line: line)
          expectation.fulfill()
        }
      }
      wait(for: [expectation], timeout: timeout)
    }
  }
 }
