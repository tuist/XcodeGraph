import Foundation
import Path
import XcodeGraph
@testable @preconcurrency import XcodeProj

public enum MockDefaults {
    public static let defaultDebugSettings: [String: Sendable] = [
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "SDKROOT": "iphoneos",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.test.app",
    ]

    public static let defaultReleaseSettings: [String: Sendable] = [
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "VALIDATE_PRODUCT": "YES",
        "SDKROOT": "iphoneos",
    ]

    public static let defaultProjectAttributes: [String: Sendable] = [
        "BuildIndependentTargetsInParallel": "YES",
    ]
}
