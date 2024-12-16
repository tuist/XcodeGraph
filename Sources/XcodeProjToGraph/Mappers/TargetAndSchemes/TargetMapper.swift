import Foundation
import Path
import XcodeGraph
import XcodeProj

/// A protocol defining how to map a `PBXTarget` into a domain `Target` model.
///
/// Conforming types transform a raw `PBXTarget` from the Xcode project model into a fully-realized `Target`
/// that includes product information, build settings, source files, resources, scripts, dependencies,
/// build rules, and other essential configuration details.
protocol TargetMapping: Sendable {
    /// Maps the given `PBXTarget` into a `Target` domain model.
    ///
    /// By inspecting the target’s build settings, build phases, and dependencies, implementers produce a `Target`
    /// that can be used for code generation, analysis, and other downstream operations.
    ///
    /// - Parameter pbxTarget: The `PBXTarget` to map.
    /// - Returns: A fully mapped `Target` model containing all relevant information extracted from the `PBXTarget`.
    /// - Throws: A `MappingError` if required information (e.g., a bundle identifier) is missing or invalid.
    func map(pbxTarget: PBXTarget) async throws -> Target
}

/// A mapper that converts a `PBXTarget` into a domain `Target` model.
///
/// `TargetMapper` orchestrates a multi-step process to produce a rich `Target` model:
/// - Uses `SettingsMapper` to translate `XCConfigurationList` into domain-specific build settings.
/// - Uses `BuildPhaseMapper` to enumerate and map sources, resources, headers, scripts, copy files, frameworks, core data models,
/// and raw script phases.
/// - Uses `BuildPhaseMapper` as well to identify additional files that are not tied to any build phase, ensuring a complete
/// picture of the project's file structure.
/// - Uses `DependencyMapper` to resolve target dependencies (e.g., other targets, packages).
/// - Uses `BuildRuleMapper` to incorporate custom build rules.
///
/// The final `Target` includes data about the platform, product type, build settings, files, dependencies, and more.
/// This comprehensive model is crucial for downstream tasks like code generation, dependency analysis, and tooling integration.
///
/// **Example Usage:**
/// ```swift
/// // Assume you have a ProjectProvider instance and a PBXTarget obtained from an Xcode project.
/// let projectProvider: ProjectProviding = ...
/// let pbxTarget: PBXTarget = ...
///
/// // Create a TargetMapper to handle the mapping of PBXTarget to Target.
/// let targetMapper = TargetMapper(projectProvider: projectProvider)
///
/// // Perform the mapping
/// let target = try await targetMapper.map(pbxTarget: pbxTarget)
///
/// // 'target' now contains a fully resolved Target model, including settings, sources, resources, dependencies, and more.
/// // This model can be used for code generation, analysis, or integration with custom development workflows.
/// ```
public final class TargetMapper: TargetMapping {
    private let projectProvider: ProjectProviding
    private let settingsMapper: SettingsMapping
    private let buildPhaseMapper: BuildPhaseMapping
    private let dependencyMapper: DependencyMapping
    private let buildRuleMapper: BuildRuleMapping

    /// Creates a new `TargetMapper` instance.
    ///
    /// - Parameter projectProvider: A provider granting access to project paths, the `XcodeProj`, and related data needed for
    /// resolution.
    public init(projectProvider: ProjectProviding) {
        self.projectProvider = projectProvider
        settingsMapper = SettingsMapper()
        buildPhaseMapper = BuildPhaseMapper(projectProvider: projectProvider)
        dependencyMapper = DependencyMapper(projectProvider: projectProvider)
        buildRuleMapper = BuildRuleMapper()
    }

    public func map(pbxTarget: PBXTarget) async throws -> Target {
        // Extract platform, product, and deployment targets
        let platform = try pbxTarget.platform()
        let deploymentTargets = try pbxTarget.deploymentTargets()
        let product = pbxTarget.productType()

        // Map build settings
        let settings = try await settingsMapper.map(
            projectProvider: projectProvider,
            configurationList: pbxTarget.buildConfigurationList
        )

        // Map various build phases
        let sources = try await buildPhaseMapper.mapSources(target: pbxTarget)
        let resources = try await buildPhaseMapper.mapResources(target: pbxTarget)
        let headers = try await buildPhaseMapper.mapHeaders(target: pbxTarget)
        let scripts = try await buildPhaseMapper.mapScripts(target: pbxTarget)
        let copyFiles = try await buildPhaseMapper.mapCopyFiles(target: pbxTarget)
        let coreDataModels = try await buildPhaseMapper.mapCoreDataModels(target: pbxTarget)
        let rawScriptBuildPhases = try await buildPhaseMapper.mapRawScriptBuildPhases(target: pbxTarget)

        // Map any additional files not included in the known build phases
        let additionalFiles = try await buildPhaseMapper.mapAdditionalFiles(target: pbxTarget)

        // Convert resource files to domain-specific `ResourceFileElements`
        let resourceFileElements = ResourceFileElements(resources)

        // Map build rules
        let buildRules = try await buildRuleMapper.mapBuildRules(target: pbxTarget)

        // Extract environment variables
        let environmentVariables = pbxTarget.extractEnvironmentVariables()

        // Extract various target-level metadata and settings
        let launchArguments = try extractLaunchArguments(from: pbxTarget)
        let filesGroup = try extractFilesGroup(from: pbxTarget)
        let playgrounds = try await extractPlaygrounds(from: pbxTarget)
        let prune = try extractPrune(from: pbxTarget)
        let mergedBinaryType = try extractMergedBinaryType(from: pbxTarget)
        let mergeable = try extractMergeable(from: pbxTarget)
        let onDemandResourcesTags = try extractOnDemandResourcesTags(from: pbxTarget)
        let metadata = try extractMetadata(from: pbxTarget)

        // Resolve dependencies (targets, packages, frameworks)
        let targetDependencies = try await dependencyMapper.mapDependencies(target: pbxTarget)
        let frameworkDependencies = try await buildPhaseMapper.mapFrameworks(target: pbxTarget)
        let allDependencies = targetDependencies + frameworkDependencies

        // Construct the final `Target` model
        return Target(
            name: pbxTarget.name,
            destinations: platform,
            product: product,
            productName: pbxTarget.productName ?? pbxTarget.name,
            bundleId: try extractBundleIdentifier(from: pbxTarget),
            deploymentTargets: deploymentTargets,
            infoPlist: try extractInfoPlist(from: pbxTarget),
            entitlements: try extractEntitlements(from: pbxTarget),
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
            dependencies: allDependencies.sorted { $0.name < $1.name },
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

    // MARK: - Helper Methods

    private func extractBundleIdentifier(from target: PBXTarget) throws -> String {
        if let bundleId = target.debugBuildSettings.string(for: .productBundleIdentifier) {
            return bundleId
        }
        throw MappingError.missingBundleIdentifier(targetName: target.name)
    }

    private func extractInfoPlist(from target: PBXTarget) throws -> InfoPlist {
        if let plistPath = try target.infoPlistPath() {
            let path = try resolvePath(plistPath)
            let plistDictionary = try readPlistAsDictionary(at: path)
            return .dictionary(plistDictionary)
        }
        return .dictionary([:])
    }

    private func readPlistAsDictionary(at path: AbsolutePath) throws -> [String: Plist.Value] {
        let fileURL = URL(fileURLWithPath: path.pathString)
        let data = try Data(contentsOf: fileURL)
        var format = PropertyListSerialization.PropertyListFormat.xml
        guard let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: .mutableContainersAndLeaves,
            format: &format
        ) as? [String: Any] else {
            throw MappingError.generic("Failed to cast plist contents to a dictionary.")
        }

        return try plist.reduce(into: [String: Plist.Value]()) { result, item in
            result[item.key] = try convertToPlistValue(item.value)
        }
    }

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

    private func extractEntitlements(from target: PBXTarget) throws -> Entitlements? {
        if let entitlementsPath = try target.entitlementsPath() {
            let resolvedPath = try resolvePath(entitlementsPath)
            return Entitlements.file(path: resolvedPath)
        }
        return nil
    }

    private func resolvePath(_ pathString: String) throws -> AbsolutePath {
        let processedPath: String
        if pathString.hasPrefix("$(SRCROOT)/") {
            let relative = String(pathString.dropFirst("$(SRCROOT)/".count))
            processedPath = relative
        } else if pathString == "$(SRCROOT)" {
            processedPath = ""
        } else {
            processedPath = pathString
        }
        return projectProvider.sourceDirectory.appending(try RelativePath(validating: processedPath))
    }

    private func extractLaunchArguments(from target: PBXTarget) throws -> [LaunchArgument] {
        guard let buildConfigList = target.buildConfigurationList else { return [] }
        var launchArguments: [LaunchArgument] = []
        for buildConfig in buildConfigList.buildConfigurations {
            if let args = buildConfig.buildSettings.stringArray(for: .launchArguments) {
                launchArguments.append(contentsOf: args.map { LaunchArgument(name: $0, isEnabled: true) })
            }
        }
        return launchArguments.uniqued()
    }

    private func extractFilesGroup(from target: PBXTarget) throws -> ProjectGroup {
        guard let mainGroup = try projectProvider.pbxProject().mainGroup else {
            throw MappingError.missingFilesGroup(targetName: target.name)
        }
        return ProjectGroup.group(name: mainGroup.name ?? "MainGroup")
    }

    private func extractPlaygrounds(from target: PBXTarget) async throws -> [AbsolutePath] {
        let sourceFiles = try await buildPhaseMapper.mapSources(target: target)
        return sourceFiles.filter { $0.path.fileExtension == .playground }.map(\.path)
    }

    private func extractPrune(from target: PBXTarget) throws -> Bool {
        target.debugBuildSettings.bool(for: .prune) ?? false
    }

    private func extractMergedBinaryType(from target: PBXTarget) throws -> MergedBinaryType {
        let mergedBinaryTypeString = target.debugBuildSettings.string(for: .mergedBinaryType)
        return mergedBinaryTypeString == "automatic" ? .automatic : .disabled
    }

    private func extractMergeable(from target: PBXTarget) throws -> Bool {
        target.debugBuildSettings.bool(for: .mergeable) ?? false
    }

    private func extractOnDemandResourcesTags(from _: PBXTarget) throws -> OnDemandResourcesTags? {
        // TODO: implement if needed
        return nil
    }

    private func extractMetadata(from target: PBXTarget) throws -> TargetMetadata {
        var tags: Set<String> = []
        for buildConfig in target.buildConfigurationList?.buildConfigurations ?? [] {
            if let tagsString = buildConfig.buildSettings.string(for: .tags) {
                let extractedTags = tagsString.split(separator: ",").map {
                    $0.trimmingCharacters(in: .whitespaces)
                }
                tags.formUnion(extractedTags)
            }
        }
        return TargetMetadata(tags: tags)
    }
}
