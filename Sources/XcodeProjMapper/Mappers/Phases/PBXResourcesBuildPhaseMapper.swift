import Foundation
import Path
import XcodeGraph
import XcodeProj

protocol PBXResourcesBuildPhaseMapping {
    func map(_ resourcesBuildPhase: PBXResourcesBuildPhase, projectProvider: ProjectProviding) throws -> [ResourceFileElement]
}

struct PBXResourcesBuildPhaseMapper: PBXResourcesBuildPhaseMapping {
    func map(_ resourcesBuildPhase: PBXResourcesBuildPhase, projectProvider: ProjectProviding) throws -> [ResourceFileElement] {
        guard let files = resourcesBuildPhase.files, !files.isEmpty else {
            return []
        }

        var resources = [ResourceFileElement]()
        for buildFile in files {
            resources.append(contentsOf: try mapResourceElement(buildFile, projectProvider: projectProvider))
        }
        return resources.sorted { $0.path < $1.path }
    }

    private func mapResourceElement(
        _ buildFile: PBXBuildFile,
        projectProvider: ProjectProviding
    ) throws -> [ResourceFileElement] {
        guard let file = buildFile.file else { return [] }
        if let variantGroup = file as? PBXVariantGroup {
            return try mapVariantGroup(variantGroup, projectProvider: projectProvider)
        } else {
            return try mapResourceElement(file, projectProvider: projectProvider)
        }
    }

    private func mapResourceElement(
        _ fileElement: PBXFileElement,
        projectProvider: ProjectProviding
    ) throws -> [ResourceFileElement] {
        if let pathString = try fileElement.fullPath(sourceRoot: projectProvider.sourcePathString) {
            let absPath = try AbsolutePath(validating: pathString)
            return [.file(path: absPath)]
        }
        return []
    }

    private func mapVariantGroup(
        _ variantGroup: PBXVariantGroup,
        projectProvider: ProjectProviding
    ) throws -> [ResourceFileElement] {
        var elements = [ResourceFileElement]()
        for child in variantGroup.children {
            let childFiles = try mapResourceElement(child, projectProvider: projectProvider)
            elements.append(contentsOf: childFiles)
        }
        return elements
    }
}
