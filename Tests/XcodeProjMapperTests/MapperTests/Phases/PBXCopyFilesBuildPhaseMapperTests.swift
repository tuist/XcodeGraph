import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeProjMapper

@Suite
struct PBXCopyFilesBuildPhaseMapperTests {
    @Test("Maps copy files actions, verifying code-sign-on-copy attributes")
    func testMapCopyFiles() throws {
        // Given
        let provider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = provider.xcodeProj.pbxproj

        let fileRef = try PBXFileReference.test(
            sourceTree: .group,
            name: "MyLibrary.dylib",
            path: "MyLibrary.dylib"
        )
        .add(to: pbxProj)
        .addToMainGroup(in: pbxProj)

        let buildFile = PBXBuildFile(
            file: fileRef,
            settings: ["ATTRIBUTES": ["CodeSignOnCopy"]]
        ).add(to: pbxProj)

        let copyFilesPhase = PBXCopyFilesBuildPhase(
            dstPath: "Libraries",
            dstSubfolderSpec: .frameworks,
            name: "Embed Libraries",
            files: [buildFile]
        )
        .add(to: pbxProj)

        try PBXNativeTarget.test(
            name: "App",
            buildPhases: [copyFilesPhase],
            productType: .application
        )
        .add(to: pbxProj)
        .add(to: pbxProj.rootObject)

        let mapper = PBXCopyFilesBuildPhaseMapper()

        // When
        let copyActions = try mapper.map([copyFilesPhase], xcodeProj: provider.xcodeProj)

        // Then
        #expect(copyActions.count == 1)

        let action = try #require(copyActions.first)
        #expect(action.name == "Embed Libraries")
        #expect(action.destination == .frameworks)
        #expect(action.subpath == "Libraries")
        #expect(action.files.count == 1)

        let fileAction = try #require(action.files.first)
        #expect(fileAction.codeSignOnCopy == true)
        #expect(fileAction.path.basename == "MyLibrary.dylib")
    }
}
