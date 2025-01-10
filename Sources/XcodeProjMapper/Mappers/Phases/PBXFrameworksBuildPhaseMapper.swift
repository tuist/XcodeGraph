import Foundation
import Path
import XcodeGraph
import XcodeProj

protocol PBXFrameworksBuildPhaseMapping {
    func map(
        _ frameworksBuildPhase: PBXFrameworksBuildPhase,
        xcodeProj: XcodeProj
    ) throws -> [TargetDependency]
}

struct PBXFrameworksBuildPhaseMapper: PBXFrameworksBuildPhaseMapping {
    private let pathMapper: PathDependencyMapping

    init(pathMapper: PathDependencyMapping = PathDependencyMapper()) {
        self.pathMapper = pathMapper
    }

    func map(_ frameworksBuildPhase: PBXFrameworksBuildPhase, xcodeProj: XcodeProj) throws -> [TargetDependency] {
        let files = frameworksBuildPhase.files ?? []
        return try files.map { try mapFrameworkDependency($0, xcodeProj: xcodeProj) }
    }

    private func mapFrameworkDependency(
        _ buildFile: PBXBuildFile,
        xcodeProj: XcodeProj
    ) throws -> TargetDependency {
        let fileRef = try buildFile.file.throwing(PBXFrameworksBuildPhaseMappingError.missingFileReference)
        let filePath = try fileRef.fullPath(sourceRoot: try xcodeProj.srcPathStringOrThrow)
            .throwing(PBXFrameworksBuildPhaseMappingError.missingFilePath(name: fileRef.name))

        let path = try AbsolutePath(validating: filePath)
        return try pathMapper.map(path: path, condition: nil)
    }
}

/// Errors that may occur when mapping framework build phase files.
enum PBXFrameworksBuildPhaseMappingError: Error, LocalizedError {
    case missingFileReference
    case missingFilePath(name: String?)

    var errorDescription: String? {
        switch self {
        case .missingFileReference:
            return "Missing PBXBuildFile file reference"
        case let .missingFilePath(name):
            return "Missing or invalid file path for PBXBuildFile: \(name ?? "Unknown")"
        }
    }
}
