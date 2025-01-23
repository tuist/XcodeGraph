import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeProjMapper

@Suite
struct PBXResourcesBuildPhaseMapperTests {
    @Test("Maps resources (like xcassets) from resources phase")
    func testMapResources() throws {
        // Given
        let xcodeProj = XcodeProj.test()
        let pbxProj = xcodeProj.pbxproj

        let assetRef = try PBXFileReference(
            sourceTree: .group,
            name: "Assets.xcassets",
            path: "Assets.xcassets"
        )
        .add(to: pbxProj)
        .addToMainGroup(in: pbxProj)
        .add(to: pbxProj)

        let buildFile = PBXBuildFile(file: assetRef).add(to: pbxProj)
        let resourcesPhase = PBXResourcesBuildPhase(files: [buildFile]).add(to: pbxProj)

        try PBXNativeTarget(
            name: "App",
            buildPhases: [resourcesPhase],
            productType: .application
        )
        .add(to: pbxProj)
        .add(to: pbxProj.rootObject)

        let mapper = PBXResourcesBuildPhaseMapper()

        // When
        let resources = try mapper.map(resourcesPhase, xcodeProj: xcodeProj)

        // Then
        #expect(resources.count == 1)
        let resource = try #require(resources.first)
        switch resource {
        case let .file(path, _, _):
            #expect(path.basename == "Assets.xcassets")
        default:
            Issue.record("Expected a file resource.")
        }
    }

    @Test("Maps localized variant groups from resources")
    func testMapVariantGroup() throws {
        // Given
        let xcodeProj = XcodeProj.test()
        let pbxProj = xcodeProj.pbxproj

        let fileRef1 = PBXFileReference.test(
            name: "Localizable.strings",
            path: "en.lproj/Localizable.strings"
        ).add(to: pbxProj)
        let fileRef2 = PBXFileReference.test(
            name: "Localizable.strings",
            path: "fr.lproj/Localizable.strings"
        ).add(to: pbxProj)

        let variantGroup = try PBXVariantGroup.mockVariant(
            children: [fileRef1, fileRef2]
        )
        .add(to: pbxProj)
        .addToMainGroup(in: pbxProj)

        let buildFile = PBXBuildFile(file: variantGroup).add(to: pbxProj)
        let resourcesPhase = PBXResourcesBuildPhase(files: [buildFile]).add(to: pbxProj)

        try PBXNativeTarget.test(buildPhases: [resourcesPhase])
            .add(to: pbxProj)
            .add(to: pbxProj.rootObject)

        let mapper = PBXResourcesBuildPhaseMapper()

        // When
        let resources = try mapper.map(resourcesPhase, xcodeProj: xcodeProj)

        // Then
        #expect(resources.count == 2)
        #expect(resources.first?.path.basename == "Localizable.strings")
    }
}
