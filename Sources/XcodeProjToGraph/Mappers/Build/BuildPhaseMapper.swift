import Foundation
import Path
import XcodeGraph
import XcodeProj

/// A protocol defining how to map various build phases of a target into domain models.
///
/// Conformers transform raw Xcode build phase data (from `PBXTarget` and associated `XcodeProj` structures)
/// into typed domain models like `SourceFile`, `ResourceFileElement`, `Headers`, `TargetScript`, and more.
///
/// This allows downstream tools or processes to work with a structured, semantic representation of the build
/// steps involved in an Xcode target.
protocol BuildPhaseMapping: Sendable {
    /// Maps source files from the target's Sources build phase.
    ///
    /// - Parameter target: The Xcode target to map.
    /// - Returns: An array of `SourceFile` instances representing the target’s source files.
    /// - Throws: If file references cannot be resolved or paths are invalid.
    func mapSources(target: PBXTarget) async throws -> [SourceFile]

    /// Maps resource files from the target's Resources build phase.
    ///
    /// - Parameter target: The Xcode target to map.
    /// - Returns: An array of `ResourceFileElement` instances representing the target’s resources.
    /// - Throws: If resource references cannot be resolved or paths are invalid.
    func mapResources(target: PBXTarget) async throws -> [ResourceFileElement]

    /// Maps headers from the target’s Headers build phase.
    ///
    /// - Parameter target: The Xcode target to map.
    /// - Returns: A `Headers` instance if headers are present, or `nil` if none found.
    /// - Throws: If header file references cannot be resolved.
    func mapHeaders(target: PBXTarget) async throws -> Headers?

    /// Maps scripts from shell script build phases.
    ///
    /// - Parameter target: The Xcode target to map.
    /// - Returns: An array of `TargetScript` instances representing each shell script build phase.
    /// - Throws: If script file references or paths cannot be resolved.
    func mapScripts(target: PBXTarget) async throws -> [TargetScript]

    /// Maps copy files build phases.
    ///
    /// - Parameter target: The Xcode target to map.
    /// - Returns: An array of `CopyFilesAction` instances describing how files are copied at build time.
    /// - Throws: If file references or paths cannot be resolved.
    func mapCopyFiles(target: PBXTarget) async throws -> [CopyFilesAction]

    /// Maps Core Data models from the target’s resource phases.
    ///
    /// - Parameter target: The Xcode target to map.
    /// - Returns: An array of `CoreDataModel` instances describing the target’s Core Data models.
    /// - Throws: If model paths cannot be resolved.
    func mapCoreDataModels(target: PBXTarget) async throws -> [CoreDataModel]

    /// Maps raw script build phases for debugging or analysis.
    ///
    /// - Parameter target: The Xcode target to map.
    /// - Returns: An array of `RawScriptBuildPhase` instances representing the raw script phases.
    func mapRawScriptBuildPhases(target: PBXTarget) async throws -> [RawScriptBuildPhase]

    /// Maps additional files that are not included in any build phase.
    ///
    /// - Parameter target: The Xcode target to map.
    /// - Returns: An array of `FileElement` for files that are part of the project but not in build phases.
    /// - Throws: If file references or paths cannot be resolved.
    func mapAdditionalFiles(target: PBXTarget) async throws -> [FileElement]

    /// Maps frameworks referenced by the target’s frameworks build phase.
    ///
    /// - Parameter target: The Xcode target to map.
    /// - Returns: An array of `TargetDependency` instances representing frameworks.
    /// - Throws: If framework references or paths cannot be resolved.
    func mapFrameworks(target: PBXTarget) async throws -> [TargetDependency]
}

/// A mapper responsible for converting the build phases of a `PBXTarget` into corresponding domain models.
///
/// The `BuildPhaseMapper` leverages `ProjectProviding` to resolve file paths and uses XcodeProj’s APIs to
/// navigate build phases (sources, resources, headers, scripts, copy files, and frameworks).
///
/// By producing strongly-typed domain models (`SourceFile`, `ResourceFileElement`, `Headers`, `TargetScript`,
/// etc.), it enables subsequent steps (like code generation, analysis, or custom tooling) to operate on a well-structured,
/// semantic representation of the target’s build phases.
public final class BuildPhaseMapper: BuildPhaseMapping {
    private let projectProvider: ProjectProviding

    /// Creates a new `BuildPhaseMapper`.
    ///
    /// - Parameter projectProvider: Provides access to the project’s paths, files, and parsed structures.
    public init(projectProvider: ProjectProviding) {
        self.projectProvider = projectProvider
    }

    public func mapSources(target: PBXTarget) async throws -> [SourceFile] {
        guard let sourcesPhase = try target.sourcesBuildPhase() else { return [] }
        return try await sourcesPhase.files?.asyncCompactMap { try await self.mapSourceFile($0) }
            .sorted { $0.path < $1.path } ?? []
    }

    public func mapResources(target: PBXTarget) async throws -> [ResourceFileElement] {
        guard let resourcesPhase = try target.resourcesBuildPhase() else { return [] }
        var resources = [ResourceFileElement]()
        for buildFile in resourcesPhase.files ?? [] {
            let resourceElements = try await mapResourceElement(buildFile)
            resources.append(contentsOf: resourceElements)
        }
        return resources.sorted { $0.path < $1.path }
    }

    public func mapHeaders(target: PBXTarget) async throws -> Headers? {
        guard let headersPhase = try target.headersBuildPhase() else { return nil }

        var publicHeaders = [AbsolutePath]()
        var privateHeaders = [AbsolutePath]()
        var projectHeaders = [AbsolutePath]()

        for buildFile in headersPhase.files ?? [] {
            if let headerInfo = try await mapHeaderFile(buildFile) {
                switch headerInfo.visibility {
                case .public: publicHeaders.append(headerInfo.path)
                case .private: privateHeaders.append(headerInfo.path)
                case .project: projectHeaders.append(headerInfo.path)
                }
            }
        }

        return Headers(
            public: publicHeaders,
            private: privateHeaders,
            project: projectHeaders
        )
    }

    public func mapScripts(target: PBXTarget) async throws -> [TargetScript] {
        let scriptPhases = target.buildPhases.compactMap { $0 as? PBXShellScriptBuildPhase }
        return try await scriptPhases.asyncCompactMap { try await self.mapScriptPhase($0, in: target) }
    }

    public func mapCopyFiles(target: PBXTarget) async throws -> [CopyFilesAction] {
        let copyFilesPhases = target.buildPhases.compactMap { $0 as? PBXCopyFilesBuildPhase }
        return try await copyFilesPhases.asyncCompactMap { try await self.mapCopyFilesPhase($0) }.sorted { $0.name < $1.name }
    }

    public func mapCoreDataModels(target: PBXTarget) async throws -> [CoreDataModel] {
        guard let resourcesPhase = try target.resourcesBuildPhase() else { return [] }
        return try resourcesPhase.files?.compactMap { try self.mapCoreDataModel($0) }
            ?? []
    }

    public func mapRawScriptBuildPhases(target: PBXTarget) async throws -> [RawScriptBuildPhase] {
        let scriptPhases = target.runScriptBuildPhases()
        return scriptPhases.compactMap { mapShellScriptBuildPhase($0) }
    }

    public func mapAdditionalFiles(target: PBXTarget) async throws -> [FileElement] {
        let xcodeProj = projectProvider.xcodeProj
        guard let pbxProject = xcodeProj.pbxproj.projects.first,
              let mainGroup = pbxProject.mainGroup
        else {
            throw MappingError.noProjectsFound(path: projectProvider.xcodeProjPath.pathString)
        }

        let allFiles = try await collectFiles(from: mainGroup)
        let filesInBuildPhases = try await getFilesInBuildPhases(target: target)
        let additionalFiles = allFiles.subtracting(filesInBuildPhases).sorted()

        return additionalFiles.map { FileElement.file(path: $0) }
    }

    public func mapFrameworks(target: PBXTarget) async throws -> [TargetDependency] {
        let frameworksPhases = target.buildPhases.compactMap { $0 as? PBXFrameworksBuildPhase }
        let allFrameworkFiles = frameworksPhases.flatMap { $0.files ?? [] }
        return try await allFrameworkFiles.asyncCompactMap { try await self.mapFrameworkDependency($0) }
    }

    // MARK: - Private Helpers

    private func mapDstSubfolderSpec(_ subfolderSpec: PBXCopyFilesBuildPhase.SubFolder?)
        -> CopyFilesAction.Destination
    {
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

    private func determineScriptOrder(target: PBXTarget, scriptPhase: PBXShellScriptBuildPhase)
        -> TargetScript.Order
    {
        guard let scriptPhaseIndex = target.buildPhases.firstIndex(of: scriptPhase) else {
            return .pre
        }
        if let sourcesPhaseIndex = target.buildPhases.firstIndex(where: { $0.buildPhase == .sources }) {
            return scriptPhaseIndex > sourcesPhaseIndex ? .post : .pre
        }
        return scriptPhaseIndex == 0 ? .pre : .post
    }

    private func mapSourceFile(_ buildFile: PBXBuildFile) async throws -> SourceFile? {
        guard let fileRef = buildFile.file,
              let pathString = try fileRef.fullPath(sourceRoot: projectProvider.sourcePathString)
        else { return nil }

        let absPath = try AbsolutePath.resolvePath(pathString)
        let settings = buildFile.settings ?? [:]
        let compilerFlags: String? = settings.string(for: .compilerFlags)
        let attributes: [String]? = settings.stringArray(for: .attributes)

        return SourceFile(
            path: absPath,
            compilerFlags: compilerFlags,
            codeGen: mapCodeGenAttribute(attributes)
        )
    }

    private func mapCopyFilesPhase(_ phase: PBXCopyFilesBuildPhase) async throws -> CopyFilesAction? {
        let files =
            try await phase.files?.asyncCompactMap { buildFile -> CopyFileElement? in
                guard let fileRef = buildFile.file,
                      let pathString = try fileRef.fullPath(
                          sourceRoot: self.projectProvider.sourcePathString
                      )
                else { return nil }

                let absolutePath = try AbsolutePath.resolvePath(pathString)
                let attributes: [String]? = buildFile.settings?.stringArray(for: .attributes)
                let codeSignOnCopy =
                    attributes?.contains(BuildFileAttribute.codeSignOnCopy.rawValue) ?? false

                return .file(path: absolutePath, condition: nil, codeSignOnCopy: codeSignOnCopy)
            } ?? []

        return CopyFilesAction(
            name: phase.name ?? BuildPhaseConstants.copyFilesDefault,
            destination: mapDstSubfolderSpec(phase.dstSubfolderSpec),
            subpath: phase.dstPath.flatMap { $0.isEmpty ? nil : $0 },
            files: files.sorted { $0.path < $1.path }
        )
    }

    private func getFilesInBuildPhases(target: PBXTarget) async throws -> Set<AbsolutePath> {
        return Set(
            try await target.buildPhases.asyncCompactMap { $0.files }
                .flatMap { $0 }
                .asyncCompactMap { buildFile -> AbsolutePath? in
                    guard let fileRef = buildFile.file,
                          let filePath = try fileRef.fullPath(
                              sourceRoot: self.projectProvider.sourcePathString
                          )
                    else {
                        return nil
                    }
                    return try AbsolutePath.resolvePath(filePath)
                }
        )
    }

    private func mapResourceElement(_ buildFile: PBXBuildFile) async throws -> [ResourceFileElement] {
        guard let file = buildFile.file else { return [] }
        if let variantGroup = file as? PBXVariantGroup {
            return try await mapVariantGroup(variantGroup)
        } else {
            return try await mapResourceElement(file)
        }
    }

    private func mapResourceElement(_ fileElement: PBXFileElement) async throws -> [ResourceFileElement] {
        if let pathString = try fileElement.fullPath(sourceRoot: projectProvider.sourcePathString) {
            let absPath = try AbsolutePath.resolvePath(pathString)
            return [.file(path: absPath)]
        }
        return []
    }

    private func mapVariantGroup(_ variantGroup: PBXVariantGroup) async throws
        -> [ResourceFileElement]
    {
        var elements = [ResourceFileElement]()
        for child in variantGroup.children {
            let childFiles = try await mapResourceElement(child)
            elements.append(contentsOf: childFiles)
        }
        return elements
    }

    private func collectFiles(from group: PBXGroup) async throws -> Set<AbsolutePath> {
        var files = Set<AbsolutePath>()
        for child in group.children {
            if let file = child as? PBXFileReference,
               let pathString = try file.fullPath(sourceRoot: projectProvider.sourcePathString),
               let absPath = try? AbsolutePath.resolvePath(pathString)
            {
                files.insert(absPath)
            } else if let subgroup = child as? PBXGroup {
                files.formUnion(try await collectFiles(from: subgroup))
            }
        }
        return files
    }

    private func mapFrameworkDependency(_ buildFile: PBXBuildFile) async throws -> TargetDependency? {
        guard let fileRef = buildFile.file,
              let filePath = try fileRef.fullPath(
                  sourceRoot: projectProvider.sourceDirectory.pathString
              )
        else { return nil }

        let absPath = try AbsolutePath.resolvePath(filePath)
        return absPath.mapByExtension(condition: nil)
    }

    private func mapHeaderFile(_ buildFile: PBXBuildFile) async throws -> HeaderInfo? {
        guard let pbxElement = buildFile.file,
              let pathString = try pbxElement.fullPath(sourceRoot: projectProvider.sourcePathString)
        else { return nil }

        let attributes: [String]? = buildFile.settings?.stringArray(for: .attributes)
        let absolutePath = try AbsolutePath.resolvePath(pathString)

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

    private func mapScriptPhase(_ scriptPhase: PBXShellScriptBuildPhase, in target: PBXTarget)
        async throws -> TargetScript?
    {
        guard let shellScript = scriptPhase.shellScript else { return nil }

        return TargetScript(
            name: scriptPhase.name ?? BuildPhaseConstants.defaultScriptName,
            order: determineScriptOrder(target: target, scriptPhase: scriptPhase),
            script: .embedded(shellScript),
            inputPaths: scriptPhase.inputPaths,
            inputFileListPaths: try AbsolutePath.resolvePaths(scriptPhase.inputFileListPaths),
            outputPaths: scriptPhase.outputPaths,
            outputFileListPaths: try AbsolutePath.resolvePaths(scriptPhase.outputFileListPaths),
            showEnvVarsInLog: scriptPhase.showEnvVarsInLog,
            basedOnDependencyAnalysis: scriptPhase.alwaysOutOfDate ? false : nil,
            runForInstallBuildsOnly: scriptPhase.runOnlyForDeploymentPostprocessing,
            shellPath: scriptPhase.shellPath ?? BuildPhaseConstants.defaultShellPath,
            dependencyFile: try AbsolutePath.resolveOptionalPath(scriptPhase.dependencyFile)
        )
    }

    private func mapShellScriptBuildPhase(_ buildPhase: PBXShellScriptBuildPhase)
        -> RawScriptBuildPhase
    {
        let name = buildPhase.name() ?? BuildPhaseConstants.unnamedScriptPhase
        let shellPath = buildPhase.shellPath ?? BuildPhaseConstants.defaultShellPath
        let script = buildPhase.shellScript ?? ""
        let showEnvVarsInLog = buildPhase.showEnvVarsInLog

        return RawScriptBuildPhase(
            name: name,
            script: script,
            showEnvVarsInLog: showEnvVarsInLog,
            hashable: false,
            shellPath: shellPath
        )
    }

    private func mapCoreDataModel(_ buildFile: PBXBuildFile) throws -> CoreDataModel? {
        guard let versionGroup = buildFile.file as? XCVersionGroup,
              versionGroup.path?.hasSuffix(FileExtension.coreData.rawValue) == true,
              let modelPathString = try versionGroup.fullPath(sourceRoot: projectProvider.sourcePathString)
        else {
            return nil
        }

        let absModelPath = try AbsolutePath.resolvePath(modelPathString)
        let versions = versionGroup.children.compactMap(\.path)
        let validatedVersions = try versions.map {
            try AbsolutePath.resolvePath($0, relativeTo: absModelPath)
        }
        let currentVersion =
            versionGroup.currentVersion?.path ?? validatedVersions.first?.pathString ?? ""

        return CoreDataModel(
            path: absModelPath,
            versions: validatedVersions,
            currentVersion: currentVersion
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

private struct HeaderInfo {
    let path: AbsolutePath
    let visibility: HeaderVisibility

    enum HeaderVisibility {
        case `public`
        case `private`
        case project
    }
}
