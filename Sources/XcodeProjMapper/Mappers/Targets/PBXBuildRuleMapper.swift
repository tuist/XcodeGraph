import Foundation
import Path
import XcodeGraph
import XcodeProj

/// A protocol defining how to map a single `PBXBuildRule` instance into a `BuildRule` domain model.
///
/// Conforming types transform an individual build rule defined in an Xcode project into a
/// structured `BuildRule` model, enabling further analysis or code generation steps to operate on
/// well-defined representations of build rules.
protocol BuildRuleMapping {
    /// Maps a single `PBXBuildRule` into a `BuildRule` model.
    ///
    /// - Parameter buildRule: The `PBXBuildRule` to map.
    /// - Returns: A `BuildRule` model if the compiler spec and file type are recognized; otherwise, `nil`.
    /// - Throws: If resolving or mapping the build rule fails.
    func map(_ buildRule: PBXBuildRule) throws -> BuildRule?
}

/// A mapper that converts a `PBXBuildRule` object into a `BuildRule` domain model.
///
/// `BuildRuleMapper` extracts known compiler specs and file types from the provided build rule.
/// If the compiler spec or file type is unknown, the build rule is ignored (returning `nil`).
struct PBXBuildRuleMapper: BuildRuleMapping {
    func map(_ buildRule: PBXBuildRule) throws -> BuildRule? {
        guard let compilerSpec = mapCompilerSpec(buildRule.compilerSpec),
              let fileType = mapFileType(buildRule.fileType)
        else {
            // Unknown compiler spec or file type encountered. Skipping this build rule.
            return nil
        }

        return BuildRule(
            compilerSpec: compilerSpec,
            fileType: fileType,
            filePatterns: buildRule.filePatterns,
            name: buildRule.name,
            outputFiles: buildRule.outputFiles,
            inputFiles: buildRule.inputFiles,
            outputFilesCompilerFlags: buildRule.outputFilesCompilerFlags,
            script: buildRule.script,
            runOncePerArchitecture: buildRule.runOncePerArchitecture
        )
    }

    // MARK: - Private Helpers

    private func mapCompilerSpec(_ compilerSpec: String) -> BuildRule.CompilerSpec? {
        BuildRule.CompilerSpec(rawValue: compilerSpec)
    }

    private func mapFileType(_ fileType: String) -> BuildRule.FileType? {
        BuildRule.FileType(rawValue: fileType)
    }
}
