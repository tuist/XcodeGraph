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
                dependencies: acceptanceTestDependencies,
                isTestingTarget: false
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
                    dependencies: unitTestDependencies,
                    isTestingTarget: false
                )
            )
        }

        if let integrationTestsTargetName {
            targets.append(
                target(
                    name: integrationTestsTargetName,
                    product: .unitTests,
                    dependencies: integrationTestsDependencies,
                    isTestingTarget: false
                )
            )
        }

        return targets
    }

    public var testTargets: [Target] {
        return unitTestTargets + acceptanceTestTargets
    }

    public var targets: [Target] {
        var targets: [Target] = sourceTargets

        if let testingTargetName {
            targets.append(
                target(
                    name: testingTargetName,
                    product: product,
                    dependencies: testingDependencies,
                    isTestingTarget: true
                )
            )
        }

        return targets + testTargets
    }

    public var sourceTargets: [Target] {
        let isStaticProduct = product == .staticLibrary || product == .staticFramework
        return [
            target(
                name: targetName,
                product: product,
                dependencies: dependencies,
                isTestingTarget: false
            ),
        ]
    }

    public var acceptanceTestsTargetName: String? {
        switch self {
        default:
            return nil
        }
    }

    public var testingTargetName: String? {
        switch self {
        default:
            return "\(rawValue)Testing"
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
        if let testingTargetName {
            dependencies.append(.target(name: testingTargetName))
        }
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
        if let testingTargetName {
            dependencies.append(contentsOf: [.target(name: testingTargetName)])
        }
        return dependencies
    }

    fileprivate func target(
        name: String,
        product: Product,
        dependencies: [TargetDependency],
        isTestingTarget: Bool
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
        if isTestingTarget {
            debugSettings["ENABLE_TESTING_SEARCH_PATHS"] = "YES"
            releaseSettings["ENABLE_TESTING_SEARCH_PATHS"] = "YES"
        }

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
