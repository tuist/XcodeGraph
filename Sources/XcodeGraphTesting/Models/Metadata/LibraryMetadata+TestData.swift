import Foundation
import Path
@testable import XcodeGraph

extension LibraryMetadata {
    public static func test(
        path: AbsolutePath = try! AbsolutePath(validating: "/Libraries/libTest/libTest.a"),
        publicHeaders: AbsolutePath = try! AbsolutePath(validating: "/Libraries/libTest/include"),
        swiftModuleMap: AbsolutePath? = try! AbsolutePath(validating: "/Libraries/libTest/libTest.swiftmodule"),
        architectures: [BinaryArchitecture] = [.arm64],
        linking: BinaryLinking = .static
    ) -> LibraryMetadata {
        LibraryMetadata(
            path: path,
            publicHeaders: publicHeaders,
            swiftModuleMap: swiftModuleMap,
            architectures: architectures,
            linking: linking
        )
    }
}
