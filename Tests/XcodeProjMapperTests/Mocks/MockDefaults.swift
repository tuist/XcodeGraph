import Foundation
import Path
import XcodeGraph
@testable import XcodeProj

enum MockDefaults {
    static let defaultDebugSettings: [String: Any] = [
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.example.debug",
    ]

    static let defaultReleaseSettings: [String: Any] = [
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "VALIDATE_PRODUCT": "YES",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.example.release",
    ]

    static let defaultProjectAttributes: [String: Any] = [
        "BuildIndependentTargetsInParallel": "YES",
    ]
}
