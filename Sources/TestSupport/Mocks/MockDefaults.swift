//
//  MockDefaults.swift
//  XcodeGraphMapper
//
//  Created by Andy Kolean on 12/13/24.
//


import Foundation
import Path
import XcodeGraph
@testable @preconcurrency import XcodeProj

public struct MockDefaults {
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
        "BuildIndependentTargetsInParallel": "YES"
    ]
}
