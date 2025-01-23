import Foundation
import Path
import XcodeGraph
import XcodeProj

/// A protocol for mapping a `PBXFrameworksBuildPhase` into associated `TargetDependency`s.
protocol PBXFrameworksBuildPhaseMapping {
    /// Maps the given frameworks build phase to a list of `TargetDependency` instances.
    ///
    /// - Parameters:
    ///   - frameworksBuildPhase: The `PBXFrameworksBuildPhase` to map.
    ///   - xcodeProj: The `XcodeProj` for path resolution.
    /// - Returns: An array of `TargetDependency` objects representing the frameworks.
    /// - Throws: If any file paths or references cannot be resolved.
    func map(
        _ frameworksBuildPhase: PBXFrameworksBuildPhase,
        xcodeProj: XcodeProj
    ) throws -> [TargetDependency]
}

/// The default mapper that converts `PBXFrameworksBuildPhase` files into `TargetDependency` models.
struct PBXFrameworksBuildPhaseMapper: PBXFrameworksBuildPhaseMapping {
    private let pathMapper: PathDependencyMapping

    init(pathMapper: PathDependencyMapping = PathDependencyMapper()) {
        self.pathMapper = pathMapper
    }

    func map(
        _ frameworksBuildPhase: PBXFrameworksBuildPhase,
        xcodeProj: XcodeProj
    ) throws -> [TargetDependency] {
        let files = frameworksBuildPhase.files ?? []
        return try files.map { try mapFrameworkDependency($0, xcodeProj: xcodeProj) }
    }

    // MARK: - Private Helpers

    /// Maps a single PBXBuildFile from the frameworks build phase to a `TargetDependency`.
    private func mapFrameworkDependency(
        _ buildFile: PBXBuildFile,
        xcodeProj: XcodeProj
    ) throws -> TargetDependency {
        let fileRef = try buildFile.file.throwing(PBXFrameworksBuildPhaseMappingError.missingFileReference)
        let filePathString = try fileRef.fullPath(sourceRoot: xcodeProj.srcPathString)
            .throwing(PBXFrameworksBuildPhaseMappingError.missingFilePath(name: fileRef.name))

        let absolutePath = try AbsolutePath(validating: filePathString)
        return try pathMapper.map(path: absolutePath, condition: nil)
    }
}

/// Errors that may occur when mapping framework build phase files.
enum PBXFrameworksBuildPhaseMappingError: Error, LocalizedError {
    case missingFileReference
    case missingFilePath(name: String?)

    var errorDescription: String? {
        switch self {
        case .missingFileReference:
            return "Missing `PBXBuildFile.file` reference."
        case let .missingFilePath(name):
            let fileName = name ?? "Unknown"
            return "Missing or invalid file path for `PBXBuildFile`: \(fileName)."
        }
    }
}
