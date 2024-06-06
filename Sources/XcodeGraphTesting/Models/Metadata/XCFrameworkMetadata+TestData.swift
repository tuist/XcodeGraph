import Foundation
import Path
@testable import XcodeGraph

extension XCFrameworkMetadata {
    public static func test(
        // swiftlint:disable:next force_try
        path: AbsolutePath = try! AbsolutePath(validating: "/XCFrameworks/XCFramework.xcframework"),
        infoPlist: XCFrameworkInfoPlist = .test(),
        primaryBinaryPath: AbsolutePath =
            // swiftlint:disable:next force_try
            try! AbsolutePath(validating: "/XCFrameworks/XCFramework.xcframework/ios-arm64/XCFramework"),
        linking: BinaryLinking = .dynamic,
        mergeable: Bool = false,
        status: FrameworkStatus = .required,
        macroPath: AbsolutePath? = nil
    ) -> XCFrameworkMetadata {
        XCFrameworkMetadata(
            path: path,
            infoPlist: infoPlist,
            primaryBinaryPath: primaryBinaryPath,
            linking: linking,
            mergeable: mergeable,
            status: status,
            macroPath: macroPath
        )
    }
}
