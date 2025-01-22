import Foundation
import Path
import XcodeGraph
import XcodeProj

protocol PBXResourcesBuildPhaseMapping {
    func map(_ resourcesBuildPhase: PBXResourcesBuildPhase, xcodeProj: XcodeProj) throws -> [ResourceFileElement]
}

struct PBXResourcesBuildPhaseMapper: PBXResourcesBuildPhaseMapping {
    func map(
        _ resourcesBuildPhase: PBXResourcesBuildPhase,
        xcodeProj: XcodeProj
    ) throws -> [ResourceFileElement] {
        let files = resourcesBuildPhase.files ?? []

        return try files.flatMap { buildFile in
            try mapResourceElement(buildFile, xcodeProj: xcodeProj)
        }
        .sorted { $0.path < $1.path }
    }

    private func mapResourceElement(
        _ buildFile: PBXBuildFile,
        xcodeProj: XcodeProj
    ) throws -> [ResourceFileElement] {
        let file = try buildFile.file
            .throwing(PBXResourcesMappingError.missingFileReference)

        if let variantGroup = file as? PBXVariantGroup {
            return try mapVariantGroup(variantGroup, xcodeProj: xcodeProj)
        } else {
            return try mapResourceElement(file, xcodeProj: xcodeProj)
        }
    }

    private func mapResourceElement(
        _ fileElement: PBXFileElement,
        xcodeProj: XcodeProj
    ) throws -> [ResourceFileElement] {
        let pathString = try fileElement.fullPath(
            sourceRoot: xcodeProj.srcPathString
        ).throwing(PBXResourcesMappingError.missingFullPath(fileElement.name ?? "Unknown"))

        return [.file(path: try AbsolutePath(validating: pathString))]
    }

    private func mapVariantGroup(
        _ variantGroup: PBXVariantGroup,
        xcodeProj: XcodeProj
    ) throws -> [ResourceFileElement] {
        try variantGroup.children.flatMap { child in
            try mapResourceElement(child, xcodeProj: xcodeProj)
        }
    }
}

/// Example error types for resource mapping
enum PBXResourcesMappingError: LocalizedError {
    case missingFileReference
    case missingFullPath(String)

    var errorDescription: String? {
        switch self {
        case .missingFileReference:
            return "Missing file reference for resource"
        case let .missingFullPath(desc):
            return "No valid path for resource file element: \(desc)"
        }
    }
}
