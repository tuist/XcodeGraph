import Foundation
import Path
import XcodeGraph
@testable @preconcurrency import XcodeProj

extension PBXFileReference {
    public static func mock(
        sourceTree: PBXSourceTree = .group,
        name: String? = nil,
        explicitFileType: String? = nil,
        path: String = "AppDelegate.swift",
        lastKnownFileType: String? = "sourcecode.swift",
        includeInIndex: Bool? = nil,
        pbxProj: PBXProj,
        addToMainGroup: Bool = true
    ) -> PBXFileReference {
        let file = PBXFileReference(
            sourceTree: sourceTree,
            name: name,
            explicitFileType: explicitFileType,
            lastKnownFileType: lastKnownFileType,
            path: path,
            includeInIndex: includeInIndex
        )
        pbxProj.add(object: file)
        if addToMainGroup, let project = pbxProj.projects.first,
           let mainGroup = project.mainGroup
        {
            mainGroup.children.append(file)
        }
        return file
    }

    public static func mockProject(
        path: String = "App.xcodeproj",
        name: String? = "App",
        sourceTree: PBXSourceTree = .sourceRoot,
        lastKnownFileType: String? = nil,
        explicitFileType: String? = nil,
        includeInIndex: Bool? = nil,
        pbxProj: PBXProj
    ) -> PBXFileReference {
        let file = PBXFileReference(
            sourceTree: sourceTree,
            name: name,
            explicitFileType: explicitFileType,
            lastKnownFileType: lastKnownFileType,
            path: path,
            includeInIndex: includeInIndex
        )
        pbxProj.add(object: file)
        return file
    }
}

extension PBXVariantGroup {
    public static func mockVariant(
        children: [PBXFileElement] = [],
        sourceTree: PBXSourceTree = .group,
        name: String? = "MainGroup",
        path: String? = "/tmp/TestProject",
        pbxProj: PBXProj,
        addToMainGroup: Bool = true
    ) -> PBXVariantGroup {
        let group = PBXVariantGroup(
            children: children,
            sourceTree: sourceTree,
            name: name,
            path: path
        )
        pbxProj.add(objects: children)
        pbxProj.add(object: group)
        if addToMainGroup, let project = pbxProj.projects.first, let mainGroup = project.mainGroup {
            mainGroup.children.append(group)
        }

        return group
    }
}

extension PBXGroup {
    public static func mock(
        children: [PBXFileElement] = [],
        sourceTree: PBXSourceTree = .group,
        name: String? = "MainGroup",
        path: String? = "/tmp/TestProject",
        pbxProj: PBXProj,
        addToMainGroup: Bool = true
    ) -> PBXGroup {
        let group = PBXGroup(
            children: children,
            sourceTree: sourceTree,
            name: name,
            path: path
        )
        pbxProj.add(objects: children)
        pbxProj.add(object: group)
        if addToMainGroup, let project = pbxProj.projects.first, let mainGroup = project.mainGroup {
            mainGroup.children.append(group)
        }

        return group
    }
}

extension XCVersionGroup {
    public static func mock(
        currentVersion: PBXFileReference? = nil,
        children: [PBXFileElement] = [],
        path: String = "DefaultGroup",
        sourceTree: PBXSourceTree = .group,
        versionGroupType: String? = nil,
        name: String? = nil,
        includeInIndex: Bool? = nil,
        wrapsLines: Bool? = nil,
        usesTabs: Bool? = nil,
        indentWidth: UInt? = nil,
        tabWidth: UInt? = nil,
        pbxProj: PBXProj
    ) -> XCVersionGroup {
        let group = XCVersionGroup(
            currentVersion: currentVersion,
            path: path,
            name: name,
            sourceTree: sourceTree,
            versionGroupType: versionGroupType,
            includeInIndex: includeInIndex,
            wrapsLines: wrapsLines,
            usesTabs: usesTabs,
            indentWidth: indentWidth,
            tabWidth: tabWidth
        )
        if let currentVersion {
            pbxProj.add(object: currentVersion)
        }
        if let project = pbxProj.projects.first, let mainGroup = project.mainGroup {
            mainGroup.children.append(group)
        }
        group.children = children
        pbxProj.add(object: group)
        pbxProj.add(objects: children)
        return group
    }
}
