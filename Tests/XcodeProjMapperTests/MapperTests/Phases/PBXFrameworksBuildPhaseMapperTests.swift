import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeProjMapper

@Suite
struct PBXFrameworksBuildPhaseMapperTests {
    @Test("Maps frameworks from frameworks phase")
    func testMapFrameworks() throws {
        let mockProvider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = mockProvider.xcodeProj.pbxproj

        let frameworkRef = try PBXFileReference(
            sourceTree: .group,
            name: "MyFramework.framework",
            path: "Frameworks/MyFramework.framework"
        )
        .add(to: pbxProj)
        .addToMainGroup(in: pbxProj)

        let frameworkBuildFile = PBXBuildFile(file: frameworkRef).add(to: pbxProj)
        let frameworksPhase = PBXFrameworksBuildPhase(files: [frameworkBuildFile]).add(to: pbxProj)

        try PBXNativeTarget(
            name: "App",
            buildPhases: [frameworksPhase],
            productType: .application
        )
        .add(to: pbxProj)
        .add(to: pbxProj.rootObject)

        let mapper = PBXFrameworksBuildPhaseMapper()
        let frameworks = try mapper.map(frameworksPhase, projectProvider: mockProvider)

        #expect(frameworks.count == 1)
        let dependency = try #require(frameworks.first)
        #expect(dependency.name == "MyFramework")
    }
}
