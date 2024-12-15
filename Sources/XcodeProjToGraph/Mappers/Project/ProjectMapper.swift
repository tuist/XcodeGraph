import Foundation
import Path
import PathKit
import XcodeGraph
import XcodeProj

/// A type that maps a project structure into a `Project` model.
protocol ProjectMapping: Sendable {
  /// Maps the current project into a `Project` model.
  ///
  /// - Returns: A fully constructed `Project` model.
  /// - Throws: An error if the mapping process fails.
  func mapProject() async throws -> Project
}

/// A mapper responsible for translating a parsed Xcode project into a `Project` model.
///
/// The `ProjectMapper` utilizes `SettingsMapper` to resolve project-level settings,
/// `TargetMapper` to map individual targets, and `PackageMapper` to resolve local and remote packages.
/// It also fetches and maps schemes using a `SchemeMapper`, integrates resource synthesizer definitions,
/// and aggregates all project-related data into a single `Project` instance.
public final class ProjectMapper: ProjectMapping {
  private let projectProvider: ProjectProviding

  /// Initializes the mapper with a given project provider.
  ///
  /// - Parameter projectProvider: A `ProjectProviding` instance capable of supplying access
  ///   to the project's files, directories, and parsed structures.
  public init(projectProvider: ProjectProviding) {
    self.projectProvider = projectProvider
  }

  /// Maps the current project into a `Project` model.
  ///
  /// This method fetches project-level settings, targets, packages, and schemes, then consolidates them
  /// into a single `Project` instance. It also retrieves resource synthesizers to facilitate code generation
  /// tasks and other downstream tooling that relies on structured resource definitions.
  ///
  /// - Returns: A fully constructed `Project` model containing settings, targets, packages, and schemes.
  /// - Throws: An error if any portion of the mapping process (e.g., reading project files or mapping targets) fails.
  public func mapProject() async throws -> Project {
    let settingsMapper = SettingsMapper()
    let pbxProject = try self.projectProvider.pbxProject()
    let settings = try await settingsMapper.map(
      projectProvider: projectProvider,
      configurationList: pbxProject.buildConfigurationList)

    let targetMapper = TargetMapper(projectProvider: projectProvider)
    let targetsArray = try await pbxProject.targets.asyncCompactMap { pbxTarget in
      try await targetMapper.map(pbxTarget: pbxTarget)
    }

    let packageMapper = PackageMapper(projectProvider: projectProvider)
    let remotePackages = try await pbxProject.remotePackages.asyncCompactMap { package in
      try await packageMapper.map(package: package)
    }
    let localPackages = try await pbxProject.localPackages.asyncCompactMap { package in
      try await packageMapper.map(package: package)
    }

    let filesGroup = ProjectGroup.group(name: pbxProject.mainGroup?.name ?? "Project")

    let schemeMapper = try SchemeMapper(graphType: .project(projectProvider.sourceDirectory))
    let userSchemes = projectProvider.xcodeProj.userData.flatMap { $0.schemes }
    let sharedSchemes = projectProvider.xcodeProj.sharedData?.schemes ?? []
    let schemes: [Scheme] =
      try await schemeMapper.mapSchemesAsync(xcschemes: userSchemes, shared: false)
      + (try await schemeMapper.mapSchemesAsync(xcschemes: sharedSchemes, shared: true))

    let lastUpgradeCheck = pbxProject.attribute(for: .lastUpgradeCheck).flatMap {
      Version(string: $0)
    }
    let defaultKnownRegions = pbxProject.knownRegions.isEmpty ? nil : pbxProject.knownRegions

    return Project(
      path: projectProvider.sourceDirectory,
      sourceRootPath: projectProvider.sourceDirectory,
      xcodeProjPath: projectProvider.sourceDirectory,
      name: pbxProject.name,
      organizationName: pbxProject.attribute(for: .organization),
      classPrefix: pbxProject.attribute(for: .classPrefix),
      defaultKnownRegions: defaultKnownRegions,
      developmentRegion: pbxProject.developmentRegion,
      options: Project.Options(
        automaticSchemesOptions: .disabled,
        disableBundleAccessors: false,
        disableShowEnvironmentVarsInScriptPhases: false,
        disableSynthesizedResourceAccessors: false,
        textSettings: .init(usesTabs: nil, indentWidth: nil, tabWidth: nil, wrapsLines: nil)
      ),
      settings: settings,
      filesGroup: filesGroup,
      targets: targetsArray.sorted(),
      packages: remotePackages + localPackages,
      schemes: schemes,
      ideTemplateMacros: nil,
      additionalFiles: [],
      resourceSynthesizers: mapResourceSynthesizers(from: pbxProject),
      lastUpgradeCheck: lastUpgradeCheck,
      type: .local
    )
  }

  /// Maps known resource synthesizer definitions from the given `PBXProject`.
  ///
  /// These synthesizers define how various resource types (e.g., strings, assets, plists) are transformed or accessed.
  /// This information can be used downstream to generate code or to provide tooling support.
  ///
  /// - Parameter pbxProject: The `PBXProject` from which to derive resource synthesizer settings.
  /// - Returns: An array of `ResourceSynthesizer` instances.
  private func mapResourceSynthesizers(from pbxProject: PBXProject) -> [ResourceSynthesizer] {
    let resourceTypes:
      [(parser: ResourceSynthesizer.Parser, extensions: [String], template: String)] = [
        (.strings, ["strings", "stringsdict"], "Strings"),
        (.assets, ["xcassets"], "Assets"),
        (.plists, ["plist"], "Plists"),
        (.fonts, ["ttf", "otf", "ttc"], "Fonts"),
        (.coreData, ["xcdatamodeld"], "CoreData"),
        (.interfaceBuilder, ["xib", "storyboard"], "InterfaceBuilder"),
        (.json, ["json"], "JSON"),
        (.yaml, ["yaml", "yml"], "YAML"),
        (.files, ["txt", "md"], "Files"),
      ]

    return resourceTypes.map { resourceType in
      ResourceSynthesizer(
        parser: resourceType.parser,
        parserOptions: [:],
        extensions: Set(resourceType.extensions),
        template: .defaultTemplate(resourceType.template)
      )
    }
  }
}

/// Attributes for project settings that can be retrieved from a `PBXProject`.
enum ProjectAttribute: String {
  case classPrefix = "CLASSPREFIX"
  case organization = "ORGANIZATIONNAME"
  case lastUpgradeCheck = "LastUpgradeCheck"
}

extension PBXProject {
  /// Retrieves the value of a specific project attribute.
  ///
  /// - Parameter attr: The attribute key to look up.
  /// - Returns: The value of the attribute if it exists, or `nil` if not found.
  func attribute(for attr: ProjectAttribute) -> String? {
    attributes[attr.rawValue] as? String
  }
}

extension SchemeMapper {
  /// Maps the given Xcode schemes asynchronously.
  ///
  /// - Parameters:
  ///   - xcschemes: An array of `XCScheme` instances to map.
  ///   - shared: A Boolean indicating whether the schemes are shared.
  /// - Returns: An array of mapped `Scheme` instances.
  /// - Throws: If mapping any scheme fails.
  func mapSchemesAsync(xcschemes: [XCScheme], shared: Bool) async throws -> [Scheme] {
    try await xcschemes.asyncCompactMap { scheme in
      try await self.mapScheme(xcscheme: scheme, shared: shared)
    }
  }
}
