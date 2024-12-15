//
//  Mc.swift
//  XcodeGraphMapper
//
//  Created by Andy Kolean on 12/13/24.
//


import Foundation
import Path
import XcodeGraph
@testable @preconcurrency import XcodeProj

public extension XCBuildConfiguration {
    static func mock(
        name: String = "Debug",
        buildSettings: [String: Sendable] = MockDefaults.defaultDebugSettings,
        baseConfiguration: PBXFileReference? = nil,
        pbxProj: PBXProj
    ) -> XCBuildConfiguration {
        let anySettings = buildSettings.reduce(into: [String: Any]()) { $0[$1.key] = $1.value }
        let config = XCBuildConfiguration(
            name: name,
            baseConfiguration: baseConfiguration,
            buildSettings: anySettings
        )
        pbxProj.add(object: config)
        return config
    }
}

public extension XCConfigurationList {
    static func mock(
        configs: [(name: String, settings: [String: Sendable])] = [
            ("Debug", MockDefaults.defaultDebugSettings),
            ("Release", MockDefaults.defaultReleaseSettings),
        ],
        defaultConfigurationName: String = "Release",
        defaultConfigurationIsVisible: Bool = false,
        proj: PBXProj
    ) -> XCConfigurationList {
        let configsAny: [(String, [String: Any])] = configs.map { name, sendableSettings in
            let anySettings = sendableSettings.reduce(into: [String: Any]()) { $0[$1.key] = $1.value }
            return (name, anySettings)
        }

        let buildConfigs: [XCBuildConfiguration] = configsAny.map { name, settings in
            let config = XCBuildConfiguration(
                name: name,
                baseConfiguration: nil,
                buildSettings: settings
            )
            proj.add(object: config)
            return config
        }

        let configList = XCConfigurationList(
            buildConfigurations: buildConfigs,
            defaultConfigurationName: defaultConfigurationName,
            defaultConfigurationIsVisible: defaultConfigurationIsVisible
        )
        proj.add(object: configList)

        return configList
    }
}
