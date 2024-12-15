import Foundation
import Path
import XcodeGraph
@testable @preconcurrency import XcodeProj

extension PBXProject {
    public static func mock(
        name: String = "MainApp",
        buildConfigurationList: XCConfigurationList? = nil,
        compatibilityVersion: String = "Xcode 14.0",
        mainGroup: PBXGroup? = nil,
        developmentRegion: String = "en",
        knownRegions: [String] = ["Base", "en"],
        productsGroup: PBXGroup? = nil,
        targets: [PBXTarget]? = nil,
        attributes: [String: Any] = MockDefaults.defaultProjectAttributes,
        packageReferences: [XCRemoteSwiftPackageReference] = [],
        pbxProj: PBXProj
    ) -> PBXProject {
        let resolvedMainGroup =
            mainGroup
            ?? PBXGroup.mock(
                children: [],
                sourceTree: .group,
                name: "MainGroup",
                path: "/tmp/TestProject",
                pbxProj: pbxProj,
                addToMainGroup: false
            )

        let resolvedBuildConfigList = buildConfigurationList ?? XCConfigurationList.mock(proj: pbxProj)
        pbxProj.add(object: resolvedBuildConfigList)

        if let productsGroup = productsGroup {
            pbxProj.add(object: productsGroup)
        }

        let projectRef = PBXFileReference.mock(
            name: "App",
            path: "App.xcodeproj",
            pbxProj: pbxProj,
            addToMainGroup: false
        )

        let proj = PBXProject(
            name: name,
            buildConfigurationList: resolvedBuildConfigList,
            compatibilityVersion: compatibilityVersion,
            preferredProjectObjectVersion: nil,
            minimizedProjectReferenceProxies: nil,
            mainGroup: resolvedMainGroup,
            developmentRegion: developmentRegion,
            hasScannedForEncodings: 0,
            knownRegions: knownRegions,
            productsGroup: productsGroup,
            projectDirPath: "",
            projects: [["B900DB68213936CC004AEC3E": projectRef]],
            projectRoots: [""],
            targets: targets ?? [],
            packages: packageReferences,
            attributes: attributes,
            targetAttributes: [:]
        )

        pbxProj.add(object: proj)
        pbxProj.rootObject = proj
        return proj
    }
}

extension XCWorkspace {
    public static func mock(
        files: [String] = [
            "App/MainApp.xcodeproj",
            "Framework1/Framework1.xcodeproj",
            "StaticFramework1/StaticFramework1.xcodeproj",
        ]
    ) -> XCWorkspace {
        let children = files.map { path in
            XCWorkspaceDataElement.file(XCWorkspaceDataFileRef(location: .group(path)))
        }
        return XCWorkspace(data: XCWorkspaceData(children: children))
    }
}

extension XcodeProj {
    public static func mock(
        projectName: String = "MainApp",
        targets: [PBXTarget] = [],
        schemes: [XCScheme] = []
    ) -> XcodeProj {
        let pbxProj = PBXProj()
        let target = targets.first ?? PBXNativeTarget.mock(pbxProj: pbxProj)

        let _ = XCBuildConfiguration.mock(
            name: "Debug",
            buildSettings: MockDefaults.defaultDebugSettings,
            pbxProj: pbxProj
        )
        let _ = XCBuildConfiguration.mock(
            name: "Release",
            buildSettings: MockDefaults.defaultReleaseSettings,
            pbxProj: pbxProj
        )

        let configList = XCConfigurationList.mock(
            configs: [
                ("Debug", MockDefaults.defaultDebugSettings),
                ("Release", MockDefaults.defaultReleaseSettings),
            ],
            proj: pbxProj
        )
        target.buildConfigurationList = configList

        let pbxProject = PBXProject.mock(
            name: projectName,
            buildConfigurationList: configList,
            targets: [target],
            pbxProj: pbxProj
        )
        pbxProj.rootObject = pbxProject

        let workspace = XCWorkspace.mock(files: ["App/\(projectName).xcodeproj"])
        return XcodeProj(workspace: workspace, pbxproj: pbxProj)
    }
}

extension PBXObjectReference {
    public static func mock(objects: PBXObjects) -> PBXObjectReference {
        PBXObjectReference(objects: objects)
    }
}

extension PBXProj {
  public func add(objects: [PBXObject]) {
    objects.forEach { add(object: $0) }
  }
}
