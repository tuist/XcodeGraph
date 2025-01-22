import Foundation
import Path
import XcodeGraph
import XcodeProj

protocol PBXSourcesBuildPhaseMapping {
    func map(_ sourcesBuildPhase: PBXSourcesBuildPhase, xcodeProj: XcodeProj) throws -> [SourceFile]
}

struct PBXSourcesBuildPhaseMapper: PBXSourcesBuildPhaseMapping {
    func map(_ sourcesBuildPhase: PBXSourcesBuildPhase, xcodeProj: XcodeProj) throws -> [SourceFile] {
        let files = sourcesBuildPhase.files ?? []

        return try files.compactMap { buildFile in
            try mapSourceFile(buildFile, xcodeProj: xcodeProj)
        }.sorted { $0.path < $1.path }
    }

    private func mapSourceFile(_ buildFile: PBXBuildFile, xcodeProj: XcodeProj) throws -> SourceFile? {
        guard let fileRef = buildFile.file,
              let pathString = try fileRef.fullPath(sourceRoot: xcodeProj.srcPathString)
        else { return nil }

        let path = try AbsolutePath(validating: pathString)
        let settings = buildFile.settings ?? [:]
        let compilerFlags: String? = settings.string(for: .compilerFlags)
        let attributes: [String]? = settings.stringArray(for: .attributes)

        return SourceFile(
            path: path,
            compilerFlags: compilerFlags,
            codeGen: mapCodeGenAttribute(attributes)
        )
    }

    private func mapCodeGenAttribute(_ attributes: [String]?) -> FileCodeGen? {
        guard let attributes else { return nil }

        if attributes.contains(FileCodeGen.public.rawValue) {
            return .public
        } else if attributes.contains(FileCodeGen.private.rawValue) {
            return .private
        } else if attributes.contains(FileCodeGen.project.rawValue) {
            return .project
        } else if attributes.contains(FileCodeGen.disabled.rawValue) {
            return .disabled
        }
        return nil
    }
}
