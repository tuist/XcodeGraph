import Foundation
import Path
import XcodeGraph
import XCTest

final class BinaryArchitectureTests: XCTestCase {
    func test_rawValue() {
        XCTAssertEqual(BinaryArchitecture.x8664.rawValue, "x86_64")
        XCTAssertEqual(BinaryArchitecture.i386.rawValue, "i386")
        XCTAssertEqual(BinaryArchitecture.armv7.rawValue, "armv7")
        XCTAssertEqual(BinaryArchitecture.armv7s.rawValue, "armv7s")
        XCTAssertEqual(BinaryArchitecture.arm64.rawValue, "arm64")
        XCTAssertEqual(BinaryArchitecture.armv7k.rawValue, "armv7k")
        XCTAssertEqual(BinaryArchitecture.arm6432.rawValue, "arm64_32")
    }
}
