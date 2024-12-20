import Foundation
import Path
import XcodeGraph
import XcodeProj

protocol PBXCoreDataModelsBuildPhaseMapping {
    func map(_ resourceFiles: [PBXBuildFile], projectProvider: ProjectProviding) throws -> [CoreDataModel]
}

struct PBXCoreDataModelsBuildPhaseMapper: PBXCoreDataModelsBuildPhaseMapping {
    func map(_ resourceFiles: [PBXBuildFile], projectProvider: ProjectProviding) throws -> [CoreDataModel] {
        try resourceFiles.compactMap { try mapCoreDataModel($0, projectProvider: projectProvider) }
    }

    private func mapCoreDataModel(_ buildFile: PBXBuildFile, projectProvider: ProjectProviding) throws -> CoreDataModel? {
        guard let versionGroup = buildFile.file as? XCVersionGroup,
              versionGroup.path?.hasSuffix(FileExtension.coreData.rawValue) == true,
              let modelPathString = try versionGroup.fullPath(sourceRoot: projectProvider.sourcePathString)
        else {
            return nil
        }

        let absModelPath = try AbsolutePath(validating: modelPathString)
        let versions = versionGroup.children.compactMap(\.path)
        let validatedVersions = try versions.map {
            try AbsolutePath(validating: $0, relativeTo: absModelPath)
        }
        let currentVersion = versionGroup.currentVersion?.path ?? validatedVersions.first?.pathString ?? ""

        return CoreDataModel(
            path: absModelPath,
            versions: validatedVersions,
            currentVersion: currentVersion
        )
    }
}
