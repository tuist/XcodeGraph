import Foundation
import Path
import XcodeGraph
import XcodeProj

extension PBXTarget {
    /// Retrieves the path to the Info.plist file from the target's build settings.
    ///
    /// - Returns: The `INFOPLIST_FILE` value if present, otherwise `nil`.
    public func infoPlistPath() throws -> String? {
        buildConfigurationList?.stringSetting(for: .infoPlistFile)
    }

    /// Retrieves the path to the entitlements file from the target's build settings.
    ///
    /// - Returns: The `CODE_SIGN_ENTITLEMENTS` value if present, otherwise `nil`.
    public func entitlementsPath() throws -> String? {
        buildConfigurationList?.stringSetting(for: .codeSignEntitlements)
    }

    /// Retrieves deployment target versions for various platforms supported by this target.
    ///
    /// Checks build configurations for:
    /// - `IPHONEOS_DEPLOYMENT_TARGET`
    /// - `MACOSX_DEPLOYMENT_TARGET`
    /// - `WATCHOS_DEPLOYMENT_TARGET`
    /// - `TVOS_DEPLOYMENT_TARGET`
    /// - `VISIONOS_DEPLOYMENT_TARGET`
    ///
    /// - Returns: A `DeploymentTargets` instance containing any discovered versions.
    public func deploymentTargets() throws -> DeploymentTargets {
        guard let configList = buildConfigurationList else {
            return DeploymentTargets(iOS: nil, macOS: nil, watchOS: nil, tvOS: nil, visionOS: nil)
        }

        let keys: [BuildSettingKey] = [
            .iPhoneOSDeploymentTarget,
            .macOSDeploymentTarget,
            .watchOSDeploymentTarget,
            .tvOSDeploymentTarget,
            .visionOSDeploymentTarget,
        ]

        let targets = configList.allDeploymentTargets(keys: keys)
        return DeploymentTargets(
            iOS: targets[.iPhoneOSDeploymentTarget],
            macOS: targets[.macOSDeploymentTarget],
            watchOS: targets[.watchOSDeploymentTarget],
            tvOS: targets[.tvOSDeploymentTarget],
            visionOS: targets[.visionOSDeploymentTarget]
        )
    }
}
