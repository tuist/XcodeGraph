import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeProjMapper

@Suite
struct PBXScriptsBuildPhaseMapperTests {
    @Test("Maps embedded run scripts with specified input/output paths")
    func testMapScripts() throws {
        let provider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = provider.xcodeProj.pbxproj

        let scriptPhase = PBXShellScriptBuildPhase.test(
            name: "Run Script",
            shellScript: "echo Hello",
            inputPaths: ["$(SRCROOT)/input.txt"],
            outputPaths: ["$(DERIVED_FILE_DIR)/output.txt"]
        ).add(to: pbxProj)

        try PBXNativeTarget.test(
            name: "App",
            buildPhases: [scriptPhase],
            productType: .application
        )
        .add(to: pbxProj)
        .add(to: pbxProj.rootObject)

        let mapper = PBXScriptsBuildPhaseMapper()
        let scripts = try mapper.map([scriptPhase], buildPhases: [scriptPhase], xcodeProj: provider.xcodeProj)

        #expect(scripts.count == 1)
        let script = try #require(scripts.first)
        #expect(script.name == "Run Script")
        #expect(script.script == .embedded("echo Hello"))
        #expect(script.inputPaths == ["$(SRCROOT)/input.txt"])
        #expect(script.outputPaths == ["$(DERIVED_FILE_DIR)/output.txt"])
    }

    @Test("Maps raw script build phases not covered by other categories")
    func testMapRawScriptBuildPhases() throws {
        let provider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = provider.xcodeProj.pbxproj

        let scriptPhase = PBXShellScriptBuildPhase.test(
            name: "Test Script"
        )
        .add(to: pbxProj)

        try PBXNativeTarget.test(
            name: "App",
            buildPhases: [scriptPhase],
            productType: .application
        )
        .add(to: pbxProj)
        .add(to: pbxProj.rootObject)

        let mapper = PBXScriptsBuildPhaseMapper()
        let rawPhases = try mapper.map([scriptPhase], buildPhases: [scriptPhase], xcodeProj: provider.xcodeProj)

        #expect(rawPhases.count == 1)
        let rawPhase = try #require(rawPhases.first)
        #expect(rawPhase.name == "Test Script")
    }
}