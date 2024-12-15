import Foundation
import Path
import XcodeGraph
import XcodeProj

/// A type that maps a `PBXTarget` into a domain `Target` model, extracting platform, product, settings, sources,
/// resources, scripts, dependencies, and other configuration details.
protocol TargetMapping: Sendable {
  /// Maps the given PBX target into a `Target` domain model.
  ///
  /// - Parameter pbxTarget: The `PBXTarget` to map.
  /// - Returns: A fully mapped `Target` model.
  /// - Throws: A `MappingError` if required information is missing or invalid.
  func map(pbxTarget: PBXTarget) async throws -> Target
}

/// A mapper that converts a `PBXTarget` into a domain `Target` model.
///
/// The `TargetMapper` relies on:
/// - `SettingsMapper` to map build settings and configurations.
/// - `BuildPhaseMapper` to map source files, resources, scripts, copy files, headers, and related build phases.
/// - `DependencyMapper` to map target dependencies.
/// - `BuildRuleMapper` to map custom build rules.
///
/// The resulting `Target` object contains comprehensive information needed for further graph operations
/// such as code generation, analysis, or integration with other tooling.
public final class TargetMapper: TargetMapping {
  private let projectProvider: ProjectProviding
  private let settingsMapper: SettingsMapping
  private let buildPhaseMapper: BuildPhaseMapping
  private let dependencyMapper: DependencyMapping
  private let buildRuleMapper: BuildRuleMapper

  /// Creates a new `TargetMapper` instance.
  ///
  /// - Parameter projectProvider: Provides access to the project’s paths, `XcodeProj`, and related information.
  public init(projectProvider: ProjectProviding) {
    self.projectProvider = projectProvider
    self.settingsMapper = SettingsMapper()
    self.buildPhaseMapper = BuildPhaseMapper(projectProvider: projectProvider)
    self.dependencyMapper = DependencyMapper(projectProvider: projectProvider)
    self.buildRuleMapper = BuildRuleMapper()
  }

  public func map(pbxTarget: PBXTarget) async throws -> Target {
    let platform = try pbxTarget.platform()
    let deploymentTargets = try pbxTarget.deploymentTargets()
    let product = pbxTarget.productType()

    let settings = try await settingsMapper.map(
      projectProvider: projectProvider,
      configurationList: pbxTarget.buildConfigurationList
    )
    let sources = try await buildPhaseMapper.mapSources(target: pbxTarget)
    let resources = try await buildPhaseMapper.mapResources(target: pbxTarget)
    let headers = try await buildPhaseMapper.mapHeaders(target: pbxTarget)
    let scripts = try await buildPhaseMapper.mapScripts(target: pbxTarget)
    let copyFiles = try await buildPhaseMapper.mapCopyFiles(target: pbxTarget)
    let coreDataModels = try await buildPhaseMapper.mapCoreDataModels(target: pbxTarget)
    let rawScriptBuildPhases = try await buildPhaseMapper.mapRawScriptBuildPhases(target: pbxTarget)
    let additionalFiles: [FileElement] = []  // Currently no extra files

    let resourceFileElements = ResourceFileElements(resources)
    let buildRules = try await buildRuleMapper.mapBuildRules(target: pbxTarget)

    let environmentVariables = pbxTarget.extractEnvironmentVariables()

    let launchArguments = try extractLaunchArguments(from: pbxTarget)
    let filesGroup = try extractFilesGroup(from: pbxTarget)
    let playgrounds = try await extractPlaygrounds(from: pbxTarget)
    let prune = try extractPrune(from: pbxTarget)
    let mergedBinaryType = try extractMergedBinaryType(from: pbxTarget)
    let mergeable = try extractMergeable(from: pbxTarget)
    let onDemandResourcesTags = try extractOnDemandResourcesTags(from: pbxTarget)
    let metadata = try extractMetadata(from: pbxTarget)

    let targetDependencies = try await dependencyMapper.mapDependencies(target: pbxTarget)
    let frameworkDependencies = try await buildPhaseMapper.mapFrameworks(target: pbxTarget)
    let allDependencies = targetDependencies + frameworkDependencies

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
    guard
      let plist = try PropertyListSerialization.propertyList(
        from: data,
        options: .mutableContainersAndLeaves,
        format: &format
      ) as? [String: Any]
    else {
      // TODO: - Better Error Message
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
    return sourceFiles.filter { $0.path.fileExtension == .playground }.map { $0.path }
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

  private func extractOnDemandResourcesTags(from target: PBXTarget) throws -> OnDemandResourcesTags?
  {
    // TODO: - implement if needed
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

extension PBXTarget {
  struct EnvironmentExtractor {
    static func extract(from buildSettings: BuildSettings) -> [String: EnvironmentVariable] {
      guard let envVars = buildSettings.stringDict(for: .environmentVariables) else {
        return [:]
      }
      return envVars.reduce(into: [:]) { result, pair in
        result[pair.key] = EnvironmentVariable(value: pair.value, isEnabled: true)
      }
    }
  }

  /// Extracts environment variables from all build configurations of the target.
  ///
  /// If multiple configurations define environment variables with the same name, the last one processed
  /// takes precedence.
  public func extractEnvironmentVariables() -> [String: EnvironmentVariable] {
    buildConfigurationList?.buildConfigurations.reduce(into: [:]) { result, config in
      result.merge(EnvironmentExtractor.extract(from: config.buildSettings)) { current, _ in current
      }
    } ?? [:]
  }

  /// Returns the build settings from the "Debug" build configuration, or an empty dictionary if not present.
  var debugBuildSettings: [String: Any] {
    buildConfigurationList?.buildConfigurations.first(where: { $0.name == "Debug" })?.buildSettings
      ?? [:]
  }
}
