import Foundation
import Path
import PathKit
import XcodeGraph
import XcodeProj

/// A protocol defining how to map a parsed Xcode project structure into a `Project` domain model.
///
/// Conforming types should read from a project provider or XcodeProj instance,
/// translating raw build settings, targets, schemes, and packages into a fully realized `Project` model.
protocol ProjectMapping: Sendable {
    /// Maps the current project into a `Project` model.
    ///
    /// This involves assembling project-level settings, targets, packages, schemes, and other metadata into a `Project`.
    /// The resulting model can serve as a basis for code generation, analysis, or other tooling operations.
    ///
    /// - Returns: A fully constructed `Project` model representing the entire project.
    /// - Throws: An error if any part of the mapping process fails, such as missing required data or invalid references.
    func mapProject() async throws -> Project
}

/// A mapper responsible for translating a parsed Xcode project into a `Project` model.
///
/// `ProjectMapper` orchestrates the mapping of all major project components:
/// - Uses `SettingsMapper` to map the project's `XCConfigurationList` into domain-specific settings.
/// - Uses `TargetMapper` to convert `PBXTarget` instances into domain-level `Target` models, including sources, resources, and
/// dependencies.
/// - Uses `PackageMapper` to resolve both remote and local Swift packages.
/// - Uses `SchemeMapper` to identify and incorporate both user and shared schemes.
/// - Integrates resource synthesizers to define code generation strategies for various resource types.
///
/// **Example Usage:**
/// ```swift
/// // Assume you have a ProjectProvider set up from your `.xcodeproj`.
/// let projectProvider: ProjectProviding = ...
///
/// // Create a ProjectMapper with the given provider.
/// let projectMapper = ProjectMapper(projectProvider: projectProvider)
///
/// // Perform the mapping to produce a domain-level Project model.
/// let project = try await projectMapper.mapProject()
///
/// // 'project' now includes all targets, settings, packages, schemes, and resource synthesizers.
/// // You can use this model for code generation, analyze dependencies, or integrate with other tools.
/// ```
public final class ProjectMapper: ProjectMapping {
    private let projectProvider: ProjectProviding

    /// Initializes the mapper with a given project provider.
    ///
    /// - Parameter projectProvider: A `ProjectProviding` instance that supplies access
    ///   to the project's directories, `.xcodeproj` file, and parsed data structures,
    ///   enabling the mapper to resolve paths, read build settings, and access targets.
    public init(projectProvider: ProjectProviding) {
        self.projectProvider = projectProvider
    }

    public func mapProject() async throws -> Project {
        let settingsMapper = SettingsMapper()
        let pbxProject = try projectProvider.pbxProject()

        // Map project-level settings
        let settings = try await settingsMapper.map(
            projectProvider: projectProvider,
            configurationList: pbxProject.buildConfigurationList
        )

        // Map targets into domain-level Target models
        let targetMapper = TargetMapper(projectProvider: projectProvider)
        let targetsArray = try await pbxProject.targets.asyncCompactMap { pbxTarget in
            try await targetMapper.map(pbxTarget: pbxTarget)
        }

        // Map packages (both remote and local)
        let packageMapper = PackageMapper(projectProvider: projectProvider)
        let remotePackages = try await pbxProject.remotePackages.asyncCompactMap { package in
            try await packageMapper.map(package: package)
        }
        let localPackages = try await pbxProject.localPackages.asyncCompactMap { package in
            try await packageMapper.map(package: package)
        }

        // Determine a files group to organize files logically
        let filesGroup = ProjectGroup.group(name: pbxProject.mainGroup?.name ?? "Project")

        // Map schemes, both user and shared, for build and test configurations
        let schemeMapper = try SchemeMapper(graphType: .project(projectProvider.sourceDirectory))
        let userSchemes = projectProvider.xcodeProj.userData.flatMap(\.schemes)
        let sharedSchemes = projectProvider.xcodeProj.sharedData?.schemes ?? []
        let schemes =
            try await schemeMapper.mapSchemesAsync(xcschemes: userSchemes, shared: false)
                + (try await schemeMapper.mapSchemesAsync(xcschemes: sharedSchemes, shared: true))

        // Retrieve the last known Xcode upgrade check version, if available
        let lastUpgradeCheck = pbxProject.attribute(for: .lastUpgradeCheck).flatMap { Version(string: $0) }

        // Determine default known regions, if any
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
            options: .init(
                automaticSchemesOptions: .disabled,
                disableBundleAccessors: false,
                disableShowEnvironmentVarsInScriptPhases: false,
                disableSynthesizedResourceAccessors: false,
                textSettings: .init(
                    usesTabs: nil,
                    indentWidth: nil,
                    tabWidth: nil,
                    wrapsLines: nil
                )
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
    /// Provides a set of default resource synthesizers that cover common resource types (e.g., `.strings`, `.xcassets`,
    /// `.plist`).
    /// Even if the project doesn't define custom synthesizers, these defaults ensure that downstream tooling always has
    /// sensible defaults.
    ///
    /// - Parameter pbxProject: The `PBXProject` from which resource synthesizer settings are derived.
    /// - Returns: An array of `ResourceSynthesizer` instances representing code generation strategies for various resource types.
    private func mapResourceSynthesizers(from _: PBXProject) -> [ResourceSynthesizer] {
        let resourceTypes: [(parser: ResourceSynthesizer.Parser, extensions: [String], template: String)] = [
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
