import Foundation
import Path
import PathKit
import XcodeGraph
import XcodeProj

/// A mapper that transforms a `.xcodeproj` (provided via `ProjectProviding`) into a `Project` domain model.
///
/// This process involves:
/// - Mapping project-level settings.
/// - Converting PBXTargets into `Target` models.
/// - Resolving both remote and local Swift packages.
/// - Identifying and integrating user and shared schemes.
/// - Providing resource synthesizers for code generation.
struct PBXProjectMapper {
    /// Maps the given Xcode project into a `Project` model.
    ///
    /// - Parameter projectProvider: Supplies access to `.xcodeproj` data and related directories.
    /// - Returns: A fully constructed `Project` model.
    /// - Throws: If reading or transforming project data fails.
    func map(xcodeProj: XcodeProj) throws -> Project {
        let settingsMapper = XCConfigurationMapper()
        let pbxProject = try xcodeProj.mainPBXProject()
        let xcodeProjPath = xcodeProj.projectPath
        let sourceDirectory = xcodeProjPath.parentDirectory

        let settings = try settingsMapper.map(
            xcodeProj: xcodeProj,
            configurationList: pbxProject.buildConfigurationList
        )

        let targetMapper = PBXTargetMapper()
        let targets = try pbxProject.targets.compactMap {
            try targetMapper.map(pbxTarget: $0, xcodeProj: xcodeProj)
        }.sorted()

        let packageMapper = XCPackageMapper()
        let remotePackages = try pbxProject.remotePackages.compactMap {
            try packageMapper.map(package: $0)
        }
        let localPackages = try pbxProject.localPackages.compactMap {
            try packageMapper.map(package: $0, sourceDirectory: sourceDirectory)
        }

        let filesGroup = ProjectGroup.group(name: pbxProject.mainGroup?.name ?? "Project")

        let schemeMapper = XCSchemeMapper()
        let graphType: XcodeMapperGraphType = .project(xcodeProj)
        let userSchemes = try xcodeProj.userData.flatMap(\.schemes).map {
            try schemeMapper.map($0, shared: false, graphType: graphType)
        }
        let sharedSchemes = try xcodeProj.sharedData?.schemes.map {
            try schemeMapper.map($0, shared: true, graphType: graphType)
        } ?? []
        let schemes = userSchemes + sharedSchemes
        let lastUpgradeCheck = pbxProject.attribute(for: .lastUpgradeCheck).flatMap { Version(string: $0) }
        let defaultKnownRegions = pbxProject.knownRegions.isEmpty ? nil : pbxProject.knownRegions

        return Project(
            path: sourceDirectory,
            sourceRootPath: sourceDirectory,
            xcodeProjPath: xcodeProjPath,
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
            targets: targets,
            packages: remotePackages + localPackages,
            schemes: schemes,
            ideTemplateMacros: nil,
            additionalFiles: [],
            resourceSynthesizers: mapResourceSynthesizers(),
            lastUpgradeCheck: lastUpgradeCheck,
            type: .local
        )
    }

    /// Returns a set of default resource synthesizers for common resource types.
    private func mapResourceSynthesizers() -> [ResourceSynthesizer] {
        ResourceSynthesizer.Parser.allCases.map { parser in
            let (exts, template) = parser.resourceTypes()
            return ResourceSynthesizer(
                parser: parser,
                parserOptions: [:],
                extensions: Set(exts),
                template: .defaultTemplate(template)
            )
        }
    }
}

extension ResourceSynthesizer.Parser {
    fileprivate func resourceTypes() -> (exts: [String], template: String) {
        switch self {
        case .strings:
            return (["strings", "stringsdict"], "Strings")
        case .stringsCatalog:
            return (["strings", "stringsdict"], "Strings")
        case .assets:
            return (["xcassets"], "Assets")
        case .plists:
            return (["plist"], "Plists")
        case .fonts:
            return (["ttf", "otf", "ttc"], "Fonts")
        case .coreData:
            return (["xcdatamodeld"], "CoreData")
        case .interfaceBuilder:
            return (["xib", "storyboard"], "InterfaceBuilder")
        case .json:
            return (["json"], "JSON")
        case .yaml:
            return (["yaml", "yml"], "YAML")
        case .files:
            return (["txt", "md"], "Files")
        }
    }
}
