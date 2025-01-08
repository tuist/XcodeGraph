import Foundation
import Path
import XcodeGraph
import XcodeProj

protocol PBXCopyFilesBuildPhaseMapping {
    func map(_ copyFilesPhases: [PBXCopyFilesBuildPhase], xcodeProj: XcodeProj) throws -> [CopyFilesAction]
}

struct PBXCopyFilesBuildPhaseMapper: PBXCopyFilesBuildPhaseMapping {
    func map(_ copyFilesPhases: [PBXCopyFilesBuildPhase], xcodeProj: XcodeProj) throws -> [CopyFilesAction] {
        try copyFilesPhases.compactMap { try mapCopyFilesPhase($0, xcodeProj: xcodeProj) }
            .sorted { $0.name < $1.name }
    }

    private func mapCopyFilesPhase(
        _ phase: PBXCopyFilesBuildPhase,
        xcodeProj: XcodeProj
    ) throws -> CopyFilesAction? {
        let files = try phase.files?.compactMap { buildFile -> CopyFileElement? in
            guard let fileRef = buildFile.file,
                  let pathString = try fileRef.fullPath(sourceRoot: try xcodeProj.srcPathStringOrThrow)
            else { return nil }

            let absolutePath = try AbsolutePath(validating: pathString)
            let attributes: [String]? = buildFile.settings?.stringArray(for: .attributes)
            let codeSignOnCopy = attributes?.contains(BuildFileAttribute.codeSignOnCopy.rawValue) ?? false

            return .file(path: absolutePath, condition: nil, codeSignOnCopy: codeSignOnCopy)
        } ?? []

        return CopyFilesAction(
            name: phase.name ?? BuildPhaseConstants.copyFilesDefault,
            destination: mapDstSubfolderSpec(phase.dstSubfolderSpec),
            subpath: phase.dstPath.flatMap { $0.isEmpty ? nil : $0 },
            files: files.sorted { $0.path < $1.path }
        )
    }

    private func mapDstSubfolderSpec(_ subfolderSpec: PBXCopyFilesBuildPhase.SubFolder?) -> CopyFilesAction.Destination {
        switch subfolderSpec {
        case .absolutePath: return .absolutePath
        case .productsDirectory: return .productsDirectory
        case .wrapper: return .wrapper
        case .executables: return .executables
        case .resources: return .resources
        case .javaResources: return .javaResources
        case .frameworks: return .frameworks
        case .sharedFrameworks: return .sharedFrameworks
        case .sharedSupport: return .sharedSupport
        case .plugins: return .plugins
        default: return .productsDirectory
        }
    }
}
