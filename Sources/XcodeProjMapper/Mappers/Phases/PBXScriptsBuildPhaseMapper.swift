import Foundation
import Path
import XcodeGraph
import XcodeProj

protocol PBXScriptsBuildPhaseMapping {
    /// Maps the given script phases into `TargetScript` models.
    ///
    /// - Parameters:
    ///   - scriptPhases: The array of `PBXShellScriptBuildPhase` to map.
    ///   - buildPhases: The complete array of the target’s `PBXBuildPhase`s, used to determine script order.
    ///   - projectProvider: Provides access to the project's directory structure.
    /// - Returns: An array of `TargetScript` models representing each shell script build phase.
    /// - Throws: If script file references or paths cannot be resolved.
    func map(
        _ scriptPhases: [PBXShellScriptBuildPhase],
        buildPhases: [PBXBuildPhase]
    ) throws -> [TargetScript]

    /// Maps raw script build phases into `RawScriptBuildPhase` models.
    ///
    /// - Parameter scriptPhases: The array of `PBXShellScriptBuildPhase` to map.
    /// - Returns: An array of `RawScriptBuildPhase` instances.
    func mapRawScriptBuildPhases(_ scriptPhases: [PBXShellScriptBuildPhase]) -> [RawScriptBuildPhase]
}

struct PBXScriptsBuildPhaseMapper: PBXScriptsBuildPhaseMapping {
    func map(
        _ scriptPhases: [PBXShellScriptBuildPhase],
        buildPhases: [PBXBuildPhase]
    ) throws -> [TargetScript] {
        try scriptPhases.compactMap {
            try mapScriptPhase($0, buildPhases: buildPhases)
        }
    }

    func mapRawScriptBuildPhases(_ scriptPhases: [PBXShellScriptBuildPhase]) -> [RawScriptBuildPhase] {
        scriptPhases.map { mapShellScriptBuildPhase($0) }
    }

    // MARK: - Private Helpers

    private func mapScriptPhase(
        _ scriptPhase: PBXShellScriptBuildPhase,
        buildPhases: [PBXBuildPhase]
    ) throws -> TargetScript? {
        guard let shellScript = scriptPhase.shellScript else { return nil }

        let inputFileListPaths = try scriptPhase.inputFileListPaths?.compactMap { try AbsolutePath(validating: $0) } ?? []

        let outputFileListPaths = try scriptPhase.outputFileListPaths?.compactMap { try AbsolutePath(validating: $0) } ?? []

        let dependencyFile = try scriptPhase.dependencyFile.map { try AbsolutePath(validating: $0) }
        return TargetScript(
            name: scriptPhase.name ?? BuildPhaseConstants.defaultScriptName,
            order: determineScriptOrder(buildPhases: buildPhases, scriptPhase: scriptPhase),
            script: .embedded(shellScript),
            inputPaths: scriptPhase.inputPaths,
            inputFileListPaths: inputFileListPaths,
            outputPaths: scriptPhase.outputPaths,
            outputFileListPaths: outputFileListPaths,
            showEnvVarsInLog: scriptPhase.showEnvVarsInLog,
            basedOnDependencyAnalysis: scriptPhase.alwaysOutOfDate ? false : nil,
            runForInstallBuildsOnly: scriptPhase.runOnlyForDeploymentPostprocessing,
            shellPath: scriptPhase.shellPath ?? BuildPhaseConstants.defaultShellPath,
            dependencyFile: dependencyFile
        )
    }

    private func mapShellScriptBuildPhase(_ buildPhase: PBXShellScriptBuildPhase) -> RawScriptBuildPhase {
        let name = buildPhase.name() ?? BuildPhaseConstants.unnamedScriptPhase
        let shellPath = buildPhase.shellPath ?? BuildPhaseConstants.defaultShellPath
        let script = buildPhase.shellScript ?? ""
        let showEnvVarsInLog = buildPhase.showEnvVarsInLog

        return RawScriptBuildPhase(
            name: name,
            script: script,
            showEnvVarsInLog: showEnvVarsInLog,
            hashable: false,
            shellPath: shellPath
        )
    }

    private func determineScriptOrder(
        buildPhases: [PBXBuildPhase],
        scriptPhase: PBXShellScriptBuildPhase
    ) -> TargetScript.Order {
        guard let scriptPhaseIndex = buildPhases.firstIndex(of: scriptPhase) else { return .pre }

        if let sourcesPhaseIndex = buildPhases.firstIndex(where: { $0.buildPhase == .sources }) {
            return scriptPhaseIndex > sourcesPhaseIndex ? .post : .pre
        }

        return scriptPhaseIndex == 0 ? .pre : .post
    }
}
