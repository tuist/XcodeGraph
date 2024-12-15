import Foundation
import Path
import XcodeGraph
import XcodeProj

/// A protocol defining how to map an Xcode project's configuration list into a `Settings` model.
protocol SettingsMapping: Sendable {
    /// Maps a given `XCConfigurationList` into `Settings`.
    ///
    /// - Parameters:
    ///   - projectProvider: A provider for project-related paths and files.
    ///   - configurationList: The `XCConfigurationList` to map.
    /// - Returns: A `Settings` model derived from the configuration list, or default settings if none are found.
    /// - Throws: If build settings cannot be mapped correctly.
    func map(projectProvider: ProjectProviding, configurationList: XCConfigurationList?) async throws
        -> Settings
}

/// A mapper responsible for converting an Xcode project's configuration list into a `Settings` domain model.
final class SettingsMapper: SettingsMapping {
    /// Creates a new `SettingsMapper`.
    public init() {}

    public func map(projectProvider: ProjectProviding, configurationList: XCConfigurationList?)
        async throws -> Settings
    {
        guard let configurationList else {
            return Settings.default
        }

        var configurations: [BuildConfiguration: Configuration?] = [:]
        for buildConfig in configurationList.buildConfigurations {
            let buildSettings = buildConfig.buildSettings
            let settingsDict = try await mapBuildSettings(buildSettings)

            var xcconfigAbsolutePath: AbsolutePath?
            if let baseConfigRef = buildConfig.baseConfiguration,
               let xcconfigPath = try baseConfigRef.fullPath(
                   sourceRoot: projectProvider.sourceDirectory.pathString
               )
            {
                xcconfigAbsolutePath = try AbsolutePath.resolvePath(xcconfigPath)
            }

            let variant = variant(forName: buildConfig.name)
            let buildConfiguration = BuildConfiguration(name: buildConfig.name, variant: variant)
            configurations[buildConfiguration] = Configuration(
                settings: settingsDict,
                xcconfig: xcconfigAbsolutePath
            )
        }

        return Settings(
            base: [:],
            baseDebug: [:],
            configurations: configurations,
            defaultSettings: .recommended
        )
    }

    /// Maps a dictionary of raw build settings into a `SettingsDictionary`.
    ///
    /// The raw values are converted into `SettingValue` instances. String and array values are directly converted,
    /// while other types are stringified as a fallback.
    ///
    /// - Parameter buildSettings: A dictionary representing the raw build settings.
    /// - Returns: A `SettingsDictionary` with mapped `SettingValue` instances.
    /// - Throws: If a setting value cannot be mapped.
    public func mapBuildSettings(_ buildSettings: [String: Any]) async throws -> SettingsDictionary {
        var settingsDict = SettingsDictionary()
        for (key, value) in buildSettings {
            settingsDict[key] = try await mapSettingValue(value)
        }
        return settingsDict
    }

    /// Maps a raw setting value into a `SettingValue`.
    ///
    /// If the value is a string, it's mapped directly.
    /// If it's an array, elements are mapped to strings if possible.
    /// Otherwise, the value is stringified.
    ///
    /// - Parameter value: The raw setting value from the build settings.
    /// - Returns: A `SettingValue` representing the mapped value.
    private func mapSettingValue(_ value: Any) async throws -> SettingValue {
        if let stringValue = value as? String {
            return .string(stringValue)
        } else if let arrayValue = value as? [Any] {
            let stringArray = arrayValue.compactMap { $0 as? String }
            return .array(stringArray)
        } else {
            // Fallback: convert non-string/non-array values to string
            let stringValue = String(describing: value)
            return .string(stringValue)
        }
    }

    /// Determines a build configuration variant (debug or release) based on its name.
    ///
    /// Uses `ConfigurationMatcher` to determine if the configuration name suggests a debug or release variant.
    ///
    /// - Parameter name: The name of the build configuration.
    /// - Returns: The corresponding `BuildConfiguration.Variant`.
    private func variant(forName name: String) -> BuildConfiguration.Variant {
        ConfigurationMatcher.variant(forName: name)
    }
}
