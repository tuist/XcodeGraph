import Foundation
import Path
import XcodeGraph
import XcodeProj

protocol PBXFrameworksBuildPhaseMapping {
    func map(_ frameworksBuildPhase: PBXFrameworksBuildPhase, projectProvider: ProjectProviding) throws -> [TargetDependency]
}

struct PBXFrameworksBuildPhaseMapper: PBXFrameworksBuildPhaseMapping {
    func map(_ frameworksBuildPhase: PBXFrameworksBuildPhase, projectProvider: ProjectProviding) throws -> [TargetDependency] {
        guard let files = frameworksBuildPhase.files, !files.isEmpty else {
            return []
        }

        return try files.compactMap { try mapFrameworkDependency($0, projectProvider: projectProvider) }
    }

    private func mapFrameworkDependency(
        _ buildFile: PBXBuildFile,
        projectProvider: ProjectProviding
    ) throws -> TargetDependency? {
        guard let fileRef = buildFile.file,
              let filePath = try fileRef.fullPath(sourceRoot: projectProvider.sourceDirectory.pathString)
        else { return nil }

        let absPath = try AbsolutePath(validating: filePath)
        return absPath.mapByExtension(condition: nil)
    }
}
