import Path
import Testing
import XcodeGraph
import XcodeProj

@testable import XcodeGraphMapper

@Suite
struct PBXFrameworksBuildPhaseMapperTests {
    @Test("Maps frameworks from frameworks phase")
    func testMapFrameworks() async throws {
        // Given
        let xcodeProj = try await XcodeProj.test()
        let pbxProj = xcodeProj.pbxproj

        let frameworkRef = try PBXFileReference(
            sourceTree: .group,
            name: "MyFramework.framework",
            path: "Frameworks/MyFramework.framework"
        )
        .add(to: pbxProj)
        .addToMainGroup(in: pbxProj)
        let frameworkBuildFile = PBXBuildFile(file: frameworkRef).add(to: pbxProj)

        let targetFrameworkRef = PBXFileReference(
            sourceTree: .buildProductsDir,
            path: "Target.framework"
        )
        let targetFrameworkBuildFile = PBXBuildFile(file: targetFrameworkRef).add(to: pbxProj)

        let frameworksPhase = PBXFrameworksBuildPhase(
            files: [
                frameworkBuildFile,
                targetFrameworkBuildFile,
            ]
        ).add(to: pbxProj)

        try PBXNativeTarget(
            name: "App",
            buildPhases: [frameworksPhase],
            productType: .application
        )
        .add(to: pbxProj)
        .add(to: pbxProj.rootObject)

        let mapper = PBXFrameworksBuildPhaseMapper()

        // When
        let frameworks = try mapper.map(frameworksPhase, xcodeProj: xcodeProj)

        // Then
        let frameworkPath = try AbsolutePath(validating: "/tmp/TestProject/Frameworks/MyFramework.framework")
        #expect(
            frameworks.sorted(by: { $0.name < $1.name }) == [
                .framework(
                    path: frameworkPath,
                    status: .required,
                    condition: nil
                ),
                .target(
                    name: "Target",
                    status: .required,
                    condition: nil
                ),
            ]
        )
    }
}
