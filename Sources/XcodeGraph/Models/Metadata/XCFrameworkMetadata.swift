import Foundation
import Path

/// The metadata associated with a precompiled xcframework
public struct XCFrameworkMetadata: Equatable {
    public var path: AbsolutePath
    public var infoPlist: XCFrameworkInfoPlist
    public var primaryBinaryPath: AbsolutePath
    public var linking: BinaryLinking
    public var mergeable: Bool
    public var status: FrameworkStatus
    public var macroPath: AbsolutePath?

    public init(
        path: AbsolutePath,
        infoPlist: XCFrameworkInfoPlist,
        primaryBinaryPath: AbsolutePath,
        linking: BinaryLinking,
        mergeable: Bool,
        status: FrameworkStatus,
        macroPath: AbsolutePath?
    ) {
        self.path = path
        self.infoPlist = infoPlist
        self.primaryBinaryPath = primaryBinaryPath
        self.linking = linking
        self.mergeable = mergeable
        self.status = status
        self.macroPath = macroPath
    }
}

#if DEBUG
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
#endif
