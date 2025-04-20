import Foundation

extension Project {
    /// Additional options related to the `Project`
    public struct Options: Codable, Hashable, Sendable {
        /// Defines how to generate automatic schemes
        public let automaticSchemesOptions: AutomaticSchemesOptions

        /// Disables generating Bundle accessors.
        public let disableBundleAccessors: Bool

        /// Tuist disables echoing the ENV in shell script build phases
        public let disableShowEnvironmentVarsInScriptPhases: Bool

        /// Disable the synthesized resource accessors generation
        public let disableSynthesizedResourceAccessors: Bool

        /// Text settings to override user ones for current project
        public let textSettings: TextSettings

        public init(
            automaticSchemesOptions: AutomaticSchemesOptions,
            disableBundleAccessors: Bool,
            disableShowEnvironmentVarsInScriptPhases: Bool,
            disableSynthesizedResourceAccessors: Bool,
            textSettings: TextSettings
        ) {
            self.automaticSchemesOptions = automaticSchemesOptions
            self.disableBundleAccessors = disableBundleAccessors
            self.disableShowEnvironmentVarsInScriptPhases = disableShowEnvironmentVarsInScriptPhases
            self.disableSynthesizedResourceAccessors = disableSynthesizedResourceAccessors
            self.textSettings = textSettings
        }
    }
}

// MARK: - AutomaticSchemesOptions

extension Project.Options {
    /// The automatic schemes options
    public enum AutomaticSchemesOptions: Codable, Hashable, Sendable {
        /// Defines how to group targets into scheme for autogenerated schemes
        public enum TargetSchemesGrouping: Codable, Hashable, Sendable {
            /// Generate a single scheme per project
            case singleScheme

            /// Group the targets according to their name suffixes
            case byNameSuffix(build: Set<String>, test: Set<String>, run: Set<String>)

            /// Do not group targets, create a scheme for each target
            case notGrouped
        }

        /// Enable autogenerated schemes
        case enabled(
            targetSchemesGrouping: TargetSchemesGrouping,
            codeCoverageEnabled: Bool,
            testingOptions: TestingOptions,
            testLanguage: String? = nil,
            testRegion: String? = nil,
            testScreenCaptureFormat: ScreenCaptureFormat? = nil,
            captureScreenshotsAutomatically: Bool,
            deleteScreenshotsWhenEachTestSucceeds: Bool,
            runLanguage: String? = nil,
            runRegion: String? = nil
        )

        /// Disable autogenerated schemes
        case disabled
    }

    /// The text settings options
    public struct TextSettings: Codable, Hashable, Sendable {
        /// Whether tabs should be used instead of spaces
        public let usesTabs: Bool?

        /// The width of space indent
        public let indentWidth: UInt?

        /// The width of tab indent
        public let tabWidth: UInt?

        /// Whether lines should be wrapped or not
        public let wrapsLines: Bool?

        public init(
            usesTabs: Bool?,
            indentWidth: UInt?,
            tabWidth: UInt?,
            wrapsLines: Bool?
        ) {
            self.usesTabs = usesTabs
            self.indentWidth = indentWidth
            self.tabWidth = tabWidth
            self.wrapsLines = wrapsLines
        }
    }
}

// MARK: - Array + ProjectOption

extension Project.Options {
    public var targetSchemesGrouping: AutomaticSchemesOptions.TargetSchemesGrouping? {
        switch automaticSchemesOptions {
        case let .enabled(targetSchemesGrouping, _, _, _, _, _, _, _, _, _):
            return targetSchemesGrouping
        case .disabled:
            return nil
        }
    }

    public var codeCoverageEnabled: Bool {
        switch automaticSchemesOptions {
        case let .enabled(_, codeCoverageEnabled, _, _, _, _, _, _, _, _):
            return codeCoverageEnabled
        case .disabled:
            return false
        }
    }

    public var testingOptions: TestingOptions {
        switch automaticSchemesOptions {
        case let .enabled(_, _, testingOptions, _, _, _, _, _, _, _):
            return testingOptions
        case .disabled:
            return []
        }
    }

    public var testLanguage: String? {
        switch automaticSchemesOptions {
        case let .enabled(_, _, _, language, _, _, _, _, _, _):
            return language
        case .disabled:
            return nil
        }
    }

    public var testRegion: String? {
        switch automaticSchemesOptions {
        case let .enabled(_, _, _, _, region, _, _, _, _, _):
            return region
        case .disabled:
            return nil
        }
    }

    public var testScreenCaptureFormat: ScreenCaptureFormat? {
        switch automaticSchemesOptions {
        case let .enabled(_, _, _, _, _, testScreenCaptureFormat, _, _, _, _):
            return testScreenCaptureFormat
        case .disabled:
            return nil
        }
    }

    public var captureScreenshotsAutomatically: Bool {
      switch automaticSchemesOptions {
      case let .enabled(_, _, _, _, _, _, captureScreenshotsAutomatically, _, _, _):
        return captureScreenshotsAutomatically
      case .disabled:
        return false
      }
    }

    public var deleteScreenshotsWhenEachTestSucceeds: Bool {
      switch automaticSchemesOptions {
      case let .enabled(_, _, _, _, _, _, _, deleteScreenshotsWhenEachTestSucceeds, _, _):
        return deleteScreenshotsWhenEachTestSucceeds
      case .disabled:
        return false
      }
    }

    public var runLanguage: String? {
        switch automaticSchemesOptions {
        case let .enabled(_, _, _, _, _, _, _, _, language, _):
            return language
        case .disabled:
            return nil
        }
    }

    public var runRegion: String? {
        switch automaticSchemesOptions {
        case let .enabled(_, _, _, _, _, _, _, _, _, region):
            return region
        case .disabled:
            return nil
        }
    }
}
