import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeProjMapper

@Suite
struct PBXCoreDataModelsBuildPhaseMapperTests {
    @Test("Maps CoreData models from version groups within resources phase")
    func testMapCoreDataModels() throws {
        let provider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = provider.xcodeProj.pbxproj

        let versionChildRef = try PBXFileReference.test(
            name: "Model.xcdatamodel",
            path: "Model.xcdatamodel"
        )
        .add(to: pbxProj)
        .addToMainGroup(in: pbxProj)

        let versionGroup = try XCVersionGroup.test(
            currentVersion: versionChildRef,
            children: [versionChildRef],
            path: "Model.xcdatamodeld",
            sourceTree: .group,
            versionGroupType: "wrapper.xcdatamodel",
            name: "Model.xcdatamodeld",
            pbxProj: pbxProj
        )
        .add(to: pbxProj)
        .addToMainGroup(in: pbxProj)

        versionGroup.currentVersion?.add(to: pbxProj)

        let buildFile = PBXBuildFile(file: versionGroup).add(to: pbxProj)
        let resourcesPhase = PBXResourcesBuildPhase(files: [buildFile]).add(to: pbxProj)

        try PBXNativeTarget.test(
            name: "App",
            buildPhases: [resourcesPhase],
            productType: .application
        )
        .add(to: pbxProj)
        .add(to: pbxProj.rootObject)

        let mapper = PBXCoreDataModelsBuildPhaseMapper()
        let models = try mapper.map([buildFile], xcodeProj: provider.xcodeProj)

        #expect(models.count == 1)
        let model = try #require(models.first)
        #expect(model.path.basename == "Model.xcdatamodeld")
        #expect(model.versions.count == 1)
        #expect(model.currentVersion.contains("Model.xcdatamodel") == true)
    }
}