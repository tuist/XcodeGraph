import Foundation
import ProjectDescription

public enum Module: String, CaseIterable {
    case xcodeGraph = "XcodeGraph"

    public var isRunnable: Bool {
        switch self {
        default:
            return false
        }
    }

    public var acceptanceTestTargets: [Target] {
        var targets: [Target] = []

        if let acceptanceTestsTargetName {
            targets.append(target(
                name: acceptanceTestsTargetName,
                product: .unitTests,
                dependencies: acceptanceTestDependencies
            ))
        }

        return targets
    }

    public var unitTestTargets: [Target] {
        var targets: [Target] = []

        if let unitTestsTargetName {
            targets.append(
                target(
                    name: unitTestsTargetName,
                    product: .unitTests,
                    dependencies: unitTestDependencies
                )
            )
        }

        if let integrationTestsTargetName {
            targets.append(
                target(
                    name: integrationTestsTargetName,
                    product: .unitTests,
                    dependencies: integrationTestsDependencies
                )
            )
        }

        return targets
    }

    public var testTargets: [Target] {
        return unitTestTargets + acceptanceTestTargets
    }

    public var targets: [Target] {
        return sourceTargets + testTargets
    }

    public var sourceTargets: [Target] {
        return [
            target(
                name: targetName,
                product: product,
                dependencies: dependencies
            ),
        ]
    }

    public var acceptanceTestsTargetName: String? {
        switch self {
        default:
            return nil
        }
    }

    public var unitTestsTargetName: String? {
        switch self {
        default:
            return "\(rawValue)Tests"
        }
    }

    public var integrationTestsTargetName: String? {
        switch self {
        case .xcodeGraph:
            return nil
        }
    }

    public var targetName: String {
        rawValue
    }

    public var product: Product {
        switch self {
        default:
            return .staticFramework
        }
    }

    public var acceptanceTestDependencies: [TargetDependency] {
        let dependencies: [TargetDependency] = switch self {
        default:
            []
        }
        return dependencies
    }

    public var strictConcurrencySetting: String? {
        switch self {
        default:
            return nil
        }
    }

    public var dependencies: [TargetDependency] {
        let dependencies: [TargetDependency] = switch self {
        case .xcodeGraph:
            [
                .external(name: "AnyCodable"),
                .external(name: "Path"),
            ]
        }
        return dependencies
    }

    public var unitTestDependencies: [TargetDependency] {
        var dependencies: [TargetDependency] = switch self {
        case .xcodeGraph:
            [
            ]
        }
        dependencies = dependencies + [.target(name: targetName)]
        return dependencies
    }

    public var testingDependencies: [TargetDependency] {
        let dependencies: [TargetDependency] = switch self {
        case .xcodeGraph:
            [
            ]
        }
        return dependencies + [.target(name: targetName)]
    }

    public var integrationTestsDependencies: [TargetDependency] {
        var dependencies: [TargetDependency] = switch self {
        case .xcodeGraph:
            []
        }
        dependencies.append(.target(name: targetName))
        return dependencies
    }

    fileprivate func target(
        name: String,
        product: Product,
        dependencies: [TargetDependency]
    ) -> Target {
        let rootFolder: String
        switch product {
        case .unitTests:
            rootFolder = "Tests"
        default:
            rootFolder = "Sources"
        }
        var debugSettings: ProjectDescription.SettingsDictionary = ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) MOCKING"]
        var releaseSettings: ProjectDescription.SettingsDictionary = [:]

        if let strictConcurrencySetting, product == .framework {
            debugSettings["SWIFT_STRICT_CONCURRENCY"] = .string(strictConcurrencySetting)
            releaseSettings["SWIFT_STRICT_CONCURRENCY"] = .string(strictConcurrencySetting)
        }

        let settings = Settings.settings(
            configurations: [
                .debug(
                    name: "Debug",
                    settings: debugSettings,
                    xcconfig: nil
                ),
                .release(
                    name: "Release",
                    settings: releaseSettings,
                    xcconfig: nil
                ),
            ]
        )
        return .target(
            name: name,
            destinations: [.mac],
            product: product,
            bundleId: "io.tuist.\(name)",
            deploymentTargets: .macOS("12.0"),
            infoPlist: .default,
            sources: ["\(rootFolder)/\(name)/**/*.swift"],
            dependencies: dependencies,
            settings: settings
        )
    }

    fileprivate var settings: Settings {
        switch self {
        default:
            return .settings(
                configurations: [
                    .debug(
                        name: "Debug",
                        settings: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) MOCKING"],
                        xcconfig: nil
                    ),
                    .release(
                        name: "Release",
                        settings: [:],
                        xcconfig: nil
                    ),
                ]
            )
        }
    }
}
