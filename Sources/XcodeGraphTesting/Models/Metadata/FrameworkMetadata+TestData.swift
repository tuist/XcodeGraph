import Foundation
import Path
@testable import XcodeGraph

extension FrameworkMetadata {
    public static func test(
        // swiftlint:disable:next force_try
        path: AbsolutePath = try! AbsolutePath(validating: "/Frameworks/TestFramework.xframework"),
        // swiftlint:disable:next force_try
        binaryPath: AbsolutePath = try! AbsolutePath(validating: "/Frameworks/TestFramework.xframework/TestFramework"),
        dsymPath: AbsolutePath? = nil,
        bcsymbolmapPaths: [AbsolutePath] = [],
        linking: BinaryLinking = .dynamic,
        architectures: [BinaryArchitecture] = [.arm64],
        status: FrameworkStatus = .required
    ) -> FrameworkMetadata {
        FrameworkMetadata(
            path: path,
            binaryPath: binaryPath,
            dsymPath: dsymPath,
            bcsymbolmapPaths: bcsymbolmapPaths,
            linking: linking,
            architectures: architectures,
            status: status
        )
    }
}
