import Foundation
import Path
@testable import XcodeGraph

extension LibraryMetadata {
    public static func test(
        // swiftlint:disable:next force_try
        path: AbsolutePath = try! AbsolutePath(validating: "/Libraries/libTest/libTest.a"),
        // swiftlint:disable:next force_try
        publicHeaders: AbsolutePath = try! AbsolutePath(validating: "/Libraries/libTest/include"),
        // swiftlint:disable:next force_try
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
