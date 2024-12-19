import Foundation
import Path
import XcodeGraph
import XcodeProj

protocol PBXHeadersBuildPhaseMapping {
    func map(_ headersBuildPhase: PBXHeadersBuildPhase, projectProvider: ProjectProviding) throws -> Headers?
}

struct PBXHeadersBuildPhaseMapper: PBXHeadersBuildPhaseMapping {
    func map(_ headersBuildPhase: PBXHeadersBuildPhase, projectProvider: ProjectProviding) throws -> Headers? {
        guard let files = headersBuildPhase.files, !files.isEmpty else {
            return nil
        }

        var publicHeaders = [AbsolutePath]()
        var privateHeaders = [AbsolutePath]()
        var projectHeaders = [AbsolutePath]()

        for buildFile in files {
            if let headerInfo = try mapHeaderFile(buildFile, projectProvider: projectProvider) {
                switch headerInfo.visibility {
                case .public: publicHeaders.append(headerInfo.path)
                case .private: privateHeaders.append(headerInfo.path)
                case .project: projectHeaders.append(headerInfo.path)
                }
            }
        }

        return Headers(public: publicHeaders, private: privateHeaders, project: projectHeaders)
    }

    private func mapHeaderFile(_ buildFile: PBXBuildFile, projectProvider: ProjectProviding) throws -> HeaderInfo? {
        guard let pbxElement = buildFile.file,
              let pathString = try pbxElement.fullPath(sourceRoot: projectProvider.sourcePathString)
        else { return nil }

        let attributes = buildFile.settings?.stringArray(for: .attributes)
        let absolutePath = try AbsolutePath(validating: pathString)

        let visibility: HeaderInfo.HeaderVisibility
        if attributes?.contains(HeaderAttribute.public.rawValue) == true {
            visibility = .public
        } else if attributes?.contains(HeaderAttribute.private.rawValue) == true {
            visibility = .private
        } else {
            visibility = .project
        }

        return HeaderInfo(path: absolutePath, visibility: visibility)
    }
}

private struct HeaderInfo {
    let path: AbsolutePath
    let visibility: HeaderVisibility

    enum HeaderVisibility {
        case `public`
        case `private`
        case project
    }
}
