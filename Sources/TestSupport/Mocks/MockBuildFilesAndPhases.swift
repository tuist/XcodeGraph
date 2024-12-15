import Foundation
import Path
import XcodeGraph
@testable @preconcurrency import XcodeProj

public extension PBXBuildFile {
    static func mock(
        file: PBXFileElement,
        settings: [String: Any]? = nil,
        pbxProj: PBXProj
    ) -> PBXBuildFile {
        let buildFile = PBXBuildFile(file: file, settings: settings)
        pbxProj.add(object: buildFile)
        return buildFile
    }
}

public extension PBXBuildRule {
    static func mock(
        compilerSpec: String = BuildRule.CompilerSpec.appleClang.rawValue,
        fileType: String = BuildRule.FileType.cSource.rawValue,
        isEditable: Bool = true,
        filePatterns: String? = "*.cpp;*.cxx;*.cc",
        name: String = "Default Build Rule",
        dependencyFile: String? = nil,
        outputFiles: [String] = ["$(DERIVED_FILE_DIR)/$(INPUT_FILE_BASE).o"],
        inputFiles: [String] = [],
        outputFilesCompilerFlags: [String]? = nil,
        script: String? = nil,
        runOncePerArchitecture: Bool? = nil,
        pbxProj: PBXProj
    ) -> PBXBuildRule {
        let rule = PBXBuildRule(
            compilerSpec: compilerSpec,
            fileType: fileType,
            isEditable: isEditable,
            filePatterns: filePatterns,
            name: name,
            dependencyFile: dependencyFile,
            outputFiles: outputFiles,
            inputFiles: inputFiles,
            outputFilesCompilerFlags: outputFilesCompilerFlags,
            script: script,
            runOncePerArchitecture: runOncePerArchitecture
        )
        pbxProj.add(object: rule)
        return rule
    }
}

public extension PBXSourcesBuildPhase {
    static func mock(
        files: [PBXBuildFile],
        pbxProj: PBXProj
    ) -> PBXSourcesBuildPhase {
        let phase = PBXSourcesBuildPhase(files: files)
        pbxProj.add(object: phase)
        return phase
    }
}

public extension PBXResourcesBuildPhase {
    static func mock(
        files: [PBXBuildFile],
        pbxProj: PBXProj
    ) -> PBXResourcesBuildPhase {
        let phase = PBXResourcesBuildPhase(files: files)
        pbxProj.add(object: phase)
        return phase
    }
}

public extension PBXFrameworksBuildPhase {
    static func mock(
        files: [PBXBuildFile],
        pbxProj: PBXProj
    ) -> PBXFrameworksBuildPhase {
        let phase = PBXFrameworksBuildPhase(files: files)
        pbxProj.add(object: phase)
        return phase
    }
}

public extension PBXShellScriptBuildPhase {
    static func mock(
        name: String? = "Embed Precompiled Frameworks",
        shellScript: String = "#!/bin/sh\necho 'Mock Shell Script'",
        inputPaths: [String] = [],
        outputPaths: [String] = [],
        inputFileListPaths: [String]? = nil,
        outputFileListPaths: [String]? = nil,
        shellPath: String = "/bin/sh",
        buildActionMask: UInt = PBXBuildPhase.defaultBuildActionMask,
        runOnlyForDeploymentPostprocessing: Bool = false,
        showEnvVarsInLog: Bool = true,
        alwaysOutOfDate: Bool = false,
        dependencyFile: String? = nil,
        pbxProj: PBXProj
    ) -> PBXShellScriptBuildPhase {
        let script = PBXShellScriptBuildPhase(
            files: [],
            name: name,
            inputPaths: inputPaths,
            outputPaths: outputPaths,
            inputFileListPaths: inputFileListPaths,
            outputFileListPaths: outputFileListPaths,
            shellPath: shellPath,
            shellScript: shellScript,
            buildActionMask: buildActionMask,
            runOnlyForDeploymentPostprocessing: runOnlyForDeploymentPostprocessing,
            showEnvVarsInLog: showEnvVarsInLog,
            alwaysOutOfDate: alwaysOutOfDate,
            dependencyFile: dependencyFile
        )
        pbxProj.add(object: script)
        return script
    }
}

public extension PBXCopyFilesBuildPhase {
    static func mock(
        name: String? = "Embed Frameworks",
        dstPath: String = "",
        dstSubfolderSpec: PBXCopyFilesBuildPhase.SubFolder = .frameworks,
        files: [PBXBuildFile] = [],
        pbxProj: PBXProj
    ) -> PBXCopyFilesBuildPhase {
        let phase = PBXCopyFilesBuildPhase(
            dstPath: dstPath,
            dstSubfolderSpec: dstSubfolderSpec,
            name: name,
            buildActionMask: PBXBuildPhase.defaultBuildActionMask,
            files: files,
            runOnlyForDeploymentPostprocessing: false
        )
        pbxProj.add(object: phase)
        return phase
    }
}
