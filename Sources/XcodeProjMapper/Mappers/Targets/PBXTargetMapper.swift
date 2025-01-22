import Foundation
import Path
import XcodeGraph
import XcodeProj

/// Errors that may occur while mapping a `PBXTarget` into a `Target`.
enum TargetMappingError: LocalizedError, Equatable {
    case noProjectsFound(path: String)
    case missingFilesGroup(targetName: String)
    case invalidPlist(path: String)
    case missingBundleIdentifier(targetName: String)

    var errorDescription: String? {
        switch self {
        case let .noProjectsFound(path):
            return "No project was found at: \(path)."
        case let .missingFilesGroup(targetName):
            return "The files group is missing for the target '\(targetName)'."
        case let .invalidPlist(path):
            return "Failed to read a valid plist dictionary from file at: \(path)."
        case let .missingBundleIdentifier(targetName):
            return "The bundle identifier is missing for the target '\(targetName)'."
        }
    }
}

/// A protocol defining how to map a `PBXTarget` into a domain-level `Target` model.
///
/// Conforming types transform raw `PBXTarget` instances—including their build phases,
/// settings, and dependencies—into fully realized `Target` models suitable for analysis,
/// code generation, or tooling integration.
protocol TargetMapping {
    /// Maps a given `PBXTarget` into a `Target` model.
    ///
    /// This involves:
    /// - Extracting platform, product, and deployment information.
    /// - Mapping build phases (sources, resources, headers, scripts, copy files, frameworks, etc.)
    /// - Resolving dependencies (project-based, frameworks, libraries, packages, SDKs).
    /// - Reading settings, launch arguments, and metadata.
    ///
    /// - Parameters:
    ///   - pbxTarget: The `PBXTarget` to map.
    ///   - projectProvider: Provides access to project paths and `XcodeProj` data.
    /// - Returns: A fully mapped `Target` model.
    /// - Throws: `TargetMappingError` if required data (like a bundle identifier) is missing,
    ///           or if necessary files/groups cannot be found.
    func map(pbxTarget: PBXTarget, xcodeProj: XcodeProj) throws -> Target
}

/// A mapper that converts a `PBXTarget` into a domain `Target` model.
///
/// `PBXTargetMapper` orchestrates various specialized mappers (e.g., sources, resources, headers)
/// and dependency resolvers to produce a comprehensive `Target` suitable for downstream tasks.
struct PBXTargetMapper: TargetMapping {
    private let settingsMapper: SettingsMapping
    private let sourcesMapper: PBXSourcesBuildPhaseMapping
    private let resourcesMapper: PBXResourcesBuildPhaseMapping
    private let headersMapper: PBXHeadersBuildPhaseMapping
    private let scriptsMapper: PBXScriptsBuildPhaseMapping
    private let copyFilesMapper: PBXCopyFilesBuildPhaseMapping
    private let coreDataModelsMapper: PBXCoreDataModelsBuildPhaseMapping
    private let frameworksMapper: PBXFrameworksBuildPhaseMapping
    private let dependencyMapper: DependencyMapping
    private let buildRuleMapper: BuildRuleMapping

    init(
        settingsMapper: SettingsMapping = XCConfigurationMapper(),
        sourcesMapper: PBXSourcesBuildPhaseMapping = PBXSourcesBuildPhaseMapper(),
        resourcesMapper: PBXResourcesBuildPhaseMapping = PBXResourcesBuildPhaseMapper(),
        headersMapper: PBXHeadersBuildPhaseMapping = PBXHeadersBuildPhaseMapper(),
        scriptsMapper: PBXScriptsBuildPhaseMapping = PBXScriptsBuildPhaseMapper(),
        copyFilesMapper: PBXCopyFilesBuildPhaseMapping = PBXCopyFilesBuildPhaseMapper(),
        coreDataModelsMapper: PBXCoreDataModelsBuildPhaseMapping = PBXCoreDataModelsBuildPhaseMapper(),
        frameworksMapper: PBXFrameworksBuildPhaseMapping = PBXFrameworksBuildPhaseMapper(),
        dependencyMapper: DependencyMapping = PBXTargetDependencyMapper(),
        buildRuleMapper: BuildRuleMapping = PBXBuildRuleMapper()
    ) {
        self.settingsMapper = settingsMapper
        self.sourcesMapper = sourcesMapper
        self.resourcesMapper = resourcesMapper
        self.headersMapper = headersMapper
        self.scriptsMapper = scriptsMapper
        self.copyFilesMapper = copyFilesMapper
        self.coreDataModelsMapper = coreDataModelsMapper
        self.frameworksMapper = frameworksMapper
        self.dependencyMapper = dependencyMapper
        self.buildRuleMapper = buildRuleMapper
    }

    func map(pbxTarget: PBXTarget, xcodeProj: XcodeProj) throws -> Target {
        let platform = try pbxTarget.platform()
        let deploymentTargets = try pbxTarget.deploymentTargets()
        let productType = pbxTarget.productType?.mapProductType()
        let product = try productType.throwing(PlatformInferenceError.noPlatformInferred(pbxTarget.name))

        let settings = try settingsMapper.map(
            xcodeProj: xcodeProj,
            configurationList: pbxTarget.buildConfigurationList
        )

        let sources = try pbxTarget.sourcesBuildPhase().map {
            try sourcesMapper.map($0, xcodeProj: xcodeProj)
        } ?? []

        let resources = try pbxTarget.resourcesBuildPhase().map {
            try resourcesMapper.map($0, xcodeProj: xcodeProj)
        } ?? []

        let headers = try pbxTarget.headersBuildPhase().map {
            try headersMapper.map($0, xcodeProj: xcodeProj)
        } ?? nil

        let runScriptPhases = pbxTarget.runScriptBuildPhases()
        let scripts = try scriptsMapper.map(
            runScriptPhases,
            buildPhases: pbxTarget.buildPhases,
            xcodeProj: xcodeProj
        )
        let rawScriptBuildPhases = scriptsMapper.mapRawScriptBuildPhases(runScriptPhases)

        let copyFilesPhases = pbxTarget.copyFilesBuildPhases()
        let copyFiles = try copyFilesMapper.map(copyFilesPhases, xcodeProj: xcodeProj)

        let resourceFiles = try pbxTarget.resourcesBuildPhase()?.files ?? []
        let coreDataModels = try coreDataModelsMapper.map(resourceFiles, xcodeProj: xcodeProj)

        let frameworksPhase = try pbxTarget.frameworksBuildPhase()
        let frameworks = try frameworksPhase.map {
            try frameworksMapper.map($0, xcodeProj: xcodeProj)
        } ?? []

        let additionalFiles = try mapAdditionalFiles(from: pbxTarget, xcodeProj: xcodeProj)
        let resourceFileElements = ResourceFileElements(resources)

        let buildRules = try pbxTarget.buildRules.compactMap {
            try buildRuleMapper.map($0)
        }

        let environmentVariables = pbxTarget.extractEnvironmentVariables()
        let launchArguments = try pbxTarget.launchArguments()
        let filesGroup = try extractFilesGroup(from: pbxTarget, xcodeProj: xcodeProj)
        let playgrounds = try extractPlaygrounds(from: pbxTarget, xcodeProj: xcodeProj)
        let prune = try pbxTarget.prune()
        let mergedBinaryType = try pbxTarget.mergedBinaryType()
        let mergeable = try pbxTarget.mergeable()
        let onDemandResourcesTags = try pbxTarget.onDemandResourcesTags()
        let metadata = try pbxTarget.metadata()

        let targetDependencies = try pbxTarget.dependencies.compactMap {
            try dependencyMapper.map($0, xcodeProj: xcodeProj)
        }
        let allDependencies = (targetDependencies + frameworks).sorted { $0.name < $1.name }

        return Target(
            name: pbxTarget.name,
            destinations: platform,
            product: product,
            productName: pbxTarget.productName ?? pbxTarget.name,
            bundleId: try pbxTarget.bundleIdentifier(),
            deploymentTargets: deploymentTargets,
            infoPlist: try extractInfoPlist(from: pbxTarget, xcodeProj: xcodeProj),
            entitlements: try extractEntitlements(from: pbxTarget, xcodeProj: xcodeProj),
            settings: settings,
            sources: sources,
            resources: resourceFileElements,
            copyFiles: copyFiles,
            headers: headers,
            coreDataModels: coreDataModels,
            scripts: scripts,
            environmentVariables: environmentVariables,
            launchArguments: launchArguments,
            filesGroup: filesGroup,
            dependencies: allDependencies,
            rawScriptBuildPhases: rawScriptBuildPhases,
            playgrounds: playgrounds,
            additionalFiles: additionalFiles,
            buildRules: buildRules,
            prune: prune,
            mergedBinaryType: mergedBinaryType,
            mergeable: mergeable,
            onDemandResourcesTags: onDemandResourcesTags,
            metadata: metadata
        )
    }

    // MARK: - Private

    /// Identifies files not included in any build phase, returning them as `FileElement` models.
    func mapAdditionalFiles(from pbxTarget: PBXTarget, xcodeProj: XcodeProj) throws -> [FileElement] {
        guard let pbxProject = xcodeProj.pbxproj.projects.first,
              let mainGroup = pbxProject.mainGroup
        else {
            throw TargetMappingError.noProjectsFound(path: xcodeProj.projectPath.pathString)
        }

        let allFiles = try collectAllFiles(from: mainGroup, xcodeProj: xcodeProj)
        let filesInBuildPhases = try filesReferencedByBuildPhases(pbxTarget: pbxTarget, xcodeProj: xcodeProj)
        let additionalFiles = allFiles.subtracting(filesInBuildPhases).sorted()
        return additionalFiles.map { FileElement.file(path: $0) }
    }

    /// Extracts the main files group for the target.
    func extractFilesGroup(from target: PBXTarget, xcodeProj: XcodeProj) throws -> ProjectGroup {
        guard let pbxProject = xcodeProj.pbxproj.projects.first,
              let mainGroup = pbxProject.mainGroup
        else {
            throw TargetMappingError.missingFilesGroup(targetName: target.name)
        }
        return ProjectGroup.group(name: mainGroup.name ?? "MainGroup")
    }

    /// Extracts and parses the project's Info.plist as a dictionary, or returns an empty dictionary if none is found.
    func extractInfoPlist(from target: PBXTarget, xcodeProj: XcodeProj) throws -> InfoPlist {
        if let plistPath = try target.infoPlistPath() {
            let path = xcodeProj.srcPath.appending(try RelativePath(validating: plistPath))
            let plistDictionary = try readPlistAsDictionary(at: path)
            return .dictionary(plistDictionary)
        }
        return .dictionary([:])
    }

    /// Extracts the target's entitlements file, if present.
    func extractEntitlements(from target: PBXTarget, xcodeProj: XcodeProj) throws -> Entitlements? {
        if let entitlementsPath = try target.entitlementsPath() {
            let path = xcodeProj.srcPath.appending(try RelativePath(validating: entitlementsPath))
            return Entitlements.file(path: path)
        }
        return nil
    }

    /// Recursively collects all files from a given `PBXGroup`.
    private func collectAllFiles(from group: PBXGroup, xcodeProj: XcodeProj) throws -> Set<AbsolutePath> {
        var files = Set<AbsolutePath>()
        for child in group.children {
            if let file = child as? PBXFileReference,
               let pathString = try file.fullPath(sourceRoot: xcodeProj.srcPathString)
            {
                let path = try AbsolutePath(validating: pathString)
                files.insert(path)
            } else if let subgroup = child as? PBXGroup {
                files.formUnion(try collectAllFiles(from: subgroup, xcodeProj: xcodeProj))
            }
        }
        return files
    }

    /// Identifies all files referenced by any build phase in the target.
    private func filesReferencedByBuildPhases(
        pbxTarget: PBXTarget,
        xcodeProj: XcodeProj
    ) throws -> Set<AbsolutePath> {
        let filePaths = try pbxTarget.buildPhases.compactMap(\.files)
            .flatMap { $0 }
            .compactMap { buildFile -> AbsolutePath? in
                guard let fileRef = buildFile.file,
                      let filePath = try fileRef.fullPath(sourceRoot: xcodeProj.srcPathString)
                else { return nil }
                return try AbsolutePath(validating: filePath)
            }
        return Set(filePaths)
    }

    /// Extracts playground files from the target's sources.
    private func extractPlaygrounds(from pbxTarget: PBXTarget, xcodeProj: XcodeProj) throws -> [AbsolutePath] {
        let sources = try pbxTarget.sourcesBuildPhase().map {
            try sourcesMapper.map($0, xcodeProj: xcodeProj)
        } ?? []
        return sources.filter { $0.path.fileExtension == .playground }.map(\.path)
    }

    /// Reads and parses a plist file into a `[String: Plist.Value]` dictionary.
    private func readPlistAsDictionary(at path: AbsolutePath) throws -> [String: Plist.Value] {
        let fileURL = URL(fileURLWithPath: path.pathString)
        let data = try Data(contentsOf: fileURL)
        var format = PropertyListSerialization.PropertyListFormat.xml
        guard let plist = try? PropertyListSerialization.propertyList(
            from: data,
            options: .mutableContainersAndLeaves,
            format: &format
        ) as? [String: Any] else {
            throw TargetMappingError.invalidPlist(path: path.pathString)
        }

        return try plist.reduce(into: [String: Plist.Value]()) { result, item in
            result[item.key] = try convertToPlistValue(item.value)
        }
    }

    /// Converts a raw plist value into a `Plist.Value`.
    private func convertToPlistValue(_ value: Any) throws -> Plist.Value {
        switch value {
        case let stringValue as String:
            return .string(stringValue)
        case let intValue as Int:
            return .integer(intValue)
        case let doubleValue as Double:
            return .real(doubleValue)
        case let boolValue as Bool:
            return .boolean(boolValue)
        case let arrayValue as [Any]:
            let convertedArray = try arrayValue.map { try convertToPlistValue($0) }
            return .array(convertedArray)
        case let dictValue as [String: Any]:
            let convertedDict = try dictValue.reduce(into: [String: Plist.Value]()) {
                dictResult, dictItem in
                dictResult[dictItem.key] = try convertToPlistValue(dictItem.value)
            }
            return .dictionary(convertedDict)
        default:
            return .string(String(describing: value))
        }
    }
}
