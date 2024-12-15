import Foundation
import Path
import XcodeGraph
@preconcurrency import XcodeProj

/// A protocol defining how to map `PBXBuildRule` instances into `BuildRule` domain models.
///
/// Conforming types transform build rules defined in Xcode projects into a structured `BuildRule` model,
/// enabling further analysis or code generation steps to operate on a well-defined representation of these rules.
protocol BuildRuleMapping: Sendable {
  /// Maps the build rules of a given `PBXTarget` into an array of `BuildRule` models.
  ///
  /// - Parameter target: The `PBXTarget` whose build rules are to be mapped.
  /// - Returns: An array of `BuildRule` models representing the target’s build rules.
  /// - Throws: If resolving or mapping any of the build rules fails.
  func mapBuildRules(target: PBXTarget) async throws -> [BuildRule]
}

/// A mapper that converts `PBXBuildRule` objects into `BuildRule` domain models.
///
/// `BuildRuleMapper` attempts to translate each `PBXBuildRule` into a `BuildRule` by resolving
/// the compiler specification and file type. If a rule references an unknown compiler spec or
/// file type, that particular rule is skipped.
final class BuildRuleMapper: BuildRuleMapping {
  public func mapBuildRules(target: PBXTarget) async throws -> [BuildRule] {
    return try await target.buildRules.asyncCompactMap { pbxBuildRule in
      guard let compilerSpec = self.mapCompilerSpec(pbxBuildRule.compilerSpec),
        let fileType = self.mapFileType(pbxBuildRule.fileType)
      else {
        // Unknown compiler spec or file type encountered. Skipping this build rule.
        return nil
      }

      return BuildRule(
        compilerSpec: compilerSpec,
        fileType: fileType,
        filePatterns: pbxBuildRule.filePatterns,
        name: pbxBuildRule.name,
        outputFiles: pbxBuildRule.outputFiles,
        inputFiles: pbxBuildRule.inputFiles,
        outputFilesCompilerFlags: pbxBuildRule.outputFilesCompilerFlags,
        script: pbxBuildRule.script,
        runOncePerArchitecture: pbxBuildRule.runOncePerArchitecture
      )
    }
  }

  /// Maps a compiler specification string to a `BuildRule.CompilerSpec`.
  ///
  /// - Parameter compilerSpec: The compiler specification string from the `PBXBuildRule`.
  /// - Returns: A `BuildRule.CompilerSpec` instance if recognized; otherwise, `nil`.
  public func mapCompilerSpec(_ compilerSpec: String) -> BuildRule.CompilerSpec? {
    BuildRule.CompilerSpec(rawValue: compilerSpec)
  }

  /// Maps a file type string to a `BuildRule.FileType`.
  ///
  /// - Parameter fileType: The file type string from the `PBXBuildRule`.
  /// - Returns: A `BuildRule.FileType` instance if recognized; otherwise, `nil`.
  public func mapFileType(_ fileType: String) -> BuildRule.FileType? {
    BuildRule.FileType(rawValue: fileType)
  }
}
