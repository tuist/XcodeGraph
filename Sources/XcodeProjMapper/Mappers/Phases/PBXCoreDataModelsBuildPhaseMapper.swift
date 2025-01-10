import Foundation
import Path
import XcodeGraph
import XcodeProj

protocol PBXCoreDataModelsBuildPhaseMapping {
    func map(_ resourceFiles: [PBXBuildFile], xcodeProj: XcodeProj) throws -> [CoreDataModel]
}

struct PBXCoreDataModelsBuildPhaseMapper: PBXCoreDataModelsBuildPhaseMapping {
    func map(_ resourceFiles: [PBXBuildFile], xcodeProj: XcodeProj) throws -> [CoreDataModel] {
        try resourceFiles.compactMap { try mapCoreDataModel($0, xcodeProj: xcodeProj) }
    }

    private func mapCoreDataModel(_ buildFile: PBXBuildFile, xcodeProj: XcodeProj) throws -> CoreDataModel? {
        guard let versionGroup = buildFile.file as? XCVersionGroup,
              versionGroup.path?.hasSuffix(FileExtension.coreData.rawValue) == true,
              let modelPathString = try versionGroup.fullPath(sourceRoot: try xcodeProj.srcPathStringOrThrow)
        else {
            return nil
        }

        let modelPath = try AbsolutePath(validating: modelPathString)
        let versions = versionGroup.children.compactMap(\.path)
        let validatedVersions = try versions.map {
            try AbsolutePath(validating: $0, relativeTo: modelPath)
        }
        let currentVersion = versionGroup.currentVersion?.path ?? validatedVersions.first?.pathString ?? ""

        return CoreDataModel(
            path: modelPath,
            versions: validatedVersions,
            currentVersion: currentVersion
        )
    }
}
