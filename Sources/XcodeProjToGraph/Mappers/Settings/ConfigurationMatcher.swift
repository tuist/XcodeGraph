import Foundation
import Path
import XcodeGraph
import XcodeProj

/// A utility that determines the variant of a build configuration (e.g., debug or release)
/// based on naming conventions and validates configuration names.
struct ConfigurationMatcher {
  /// Represents a pattern mapping a set of keywords to a configuration variant.
  private struct Pattern {
    let keywords: Set<String>
    let variant: BuildConfiguration.Variant
  }

  /// Common patterns for identifying build configuration variants.
  private static let patterns: [Pattern] = [
    Pattern(keywords: ["debug", "development", "dev"], variant: .debug),
    Pattern(keywords: ["release", "prod", "production"], variant: .release),
  ]

  /// Returns the build configuration variant for a given configuration name.
  ///
  /// This method lowercases the name and checks if it contains any keywords for known variants.
  /// If none match, it defaults to `.debug`.
  ///
  /// - Parameter name: The name of the build configuration.
  /// - Returns: The determined `BuildConfiguration.Variant` for the given name.
  static public func variant(forName name: String) -> BuildConfiguration.Variant {
    let lowercased = name.lowercased()
    return patterns.first { pattern in
      pattern.keywords.contains { lowercased.contains($0) }
    }?.variant ?? .debug
  }

  /// Validates that a configuration name is non-empty and contains no whitespace.
  ///
  /// - Parameter name: The configuration name to validate.
  /// - Returns: `true` if the name is valid; `false` otherwise.
  static public func validateConfigurationName(_ name: String) -> Bool {
    !name.isEmpty && name.rangeOfCharacter(from: .whitespaces) == nil
  }
}
