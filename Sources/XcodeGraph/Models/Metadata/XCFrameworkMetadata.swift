import Foundation
import Path

/// The metadata associated with a precompiled xcframework
public struct XCFrameworkMetadata: Equatable {
    public var path: AbsolutePath
    public var infoPlist: XCFrameworkInfoPlist
    public var linking: BinaryLinking
    public var mergeable: Bool
    public var status: LinkingStatus
    public var macroPath: AbsolutePath?

    public init(
        path: AbsolutePath,
        infoPlist: XCFrameworkInfoPlist,
        linking: BinaryLinking,
        mergeable: Bool,
        status: LinkingStatus,
        macroPath: AbsolutePath?
    ) {
        self.path = path
        self.infoPlist = infoPlist
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
            linking: BinaryLinking = .dynamic,
            mergeable: Bool = false,
            status: LinkingStatus = .required,
            macroPath: AbsolutePath? = nil
        ) -> XCFrameworkMetadata {
            XCFrameworkMetadata(
                path: path,
                infoPlist: infoPlist,
                linking: linking,
                mergeable: mergeable,
                status: status,
                macroPath: macroPath
            )
        }
    }
#endif
