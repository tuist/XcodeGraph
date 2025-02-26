import Foundation

/// Keys representing various build settings that may appear in an Xcode project or workspace configuration.
enum BuildSettingKey: String {
    case sdkroot = "SDKROOT"
    case codeSignOnCopy = "CODE_SIGN_ON_COPY"

    case productBundleIdentifier = "PRODUCT_BUNDLE_IDENTIFIER"
    case infoPlistFile = "INFOPLIST_FILE"
    case codeSignEntitlements = "CODE_SIGN_ENTITLEMENTS"
    case iPhoneOSDeploymentTarget = "IPHONEOS_DEPLOYMENT_TARGET"
    case macOSDeploymentTarget = "MACOSX_DEPLOYMENT_TARGET"
    case watchOSDeploymentTarget = "WATCHOS_DEPLOYMENT_TARGET"
    case tvOSDeploymentTarget = "TVOS_DEPLOYMENT_TARGET"
    case visionOSDeploymentTarget = "VISIONOS_DEPLOYMENT_TARGET"
}

enum TuistBuildSettingKey: String {
    case launchArguments = "LAUNCH_ARGUMENTS" // Used for scheme generation
    case environmentVariables = "ENVIRONMENT_VARIABLES" // Used for scheme generation
    case tags = "TAGS" // metadata
    case prune = "PRUNE"
    case mergeable = "MERGEABLE" // Mergable library build settings generation
    case mergedBinaryType = "MERGED_BINARY_TYPE" // Default settings configuration for mergable libraries
}

enum TuistScriptSettingKey: String {
    case showEnvVarsInLog = "SHOW_ENV_VARS_IN_LOG"
    case shellPath = "SHELL_PATH"
    case dependencyFile = "DEPENDENCY_FILE"
    case inputPaths = "INPUT_PATHS"
    case outputPaths = "OUTPUT_PATHS"
}

enum BuildFileSettings: String {
    case compilerFlags = "COMPILER_FLAGS"
    case attributes = "ATTRIBUTES"
}



/// A protocol representing a type that can parse a build setting value from a generic `Any`.
protocol BuildSettingValue {
    associatedtype Value
    static func parse(_ any: Any) -> Value?
}

/// A type that parses build settings as strings.
enum BuildSettingString: BuildSettingValue {
    static func parse(_ any: Any) -> String? {
        any as? String
    }
}

/// A type that parses build settings as arrays of strings.
enum BuildSettingStringArray: BuildSettingValue {
    static func parse(_ any: Any) -> [String]? {
        let arr = any as? [Any]
        return arr?.compactMap { $0 as? String }
    }
}

extension [String: Any] {
    /// Extracts a build setting value of a specified type from the dictionary.
    ///
    /// - Parameters:
    ///   - key: The `BuildSettingKey` to look up.
    ///   - type: The type conforming to `BuildSettingValue` indicating the expected value type.
    /// - Returns: The parsed value if found and valid, or `nil` otherwise.
    func extractBuildSetting<T: BuildSettingValue>(_ key: BuildSettingKey, as _: T.Type = T.self)
        -> T.Value?
    {
        guard let value = self[key.rawValue] else { return nil }
        return T.parse(value)
    }
}

extension [String: Any] {
    /// Retrieves a string value for the given build setting key.
    func string(for key: BuildSettingKey) -> String? {
        extractBuildSetting(key, as: BuildSettingString.self)
    }

    /// Retrieves an array of strings for the given build setting key.
    func stringArray(for key: BuildSettingKey) -> [String]? {
        extractBuildSetting(key, as: BuildSettingStringArray.self)
    }
}
