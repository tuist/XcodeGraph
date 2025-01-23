import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeProjMapper

@Suite
struct PBXSourcesBuildPhaseMapperTests {
    @Test("Maps Swift source files with compiler flags from sources phase")
    func testMapSources() throws {
        // Given
        let mockProvider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = mockProvider.xcodeProj.pbxproj

        // Create a file reference for a Swift source and add it to the main group.
        let fileRef = try PBXFileReference(
            sourceTree: .group,
            name: "main.swift",
            path: "main.swift"
        )
        .add(to: pbxProj)
        .addToMainGroup(in: pbxProj)

        // Add a build file with compiler flags.
        let buildFile = PBXBuildFile(
            file: fileRef,
            settings: ["COMPILER_FLAGS": "-DDEBUG"]
        )
        .add(to: pbxProj)

        // Create a sources build phase with the file.
        let sourcesPhase = PBXSourcesBuildPhase(files: [buildFile])
            .add(to: pbxProj)

        // Add a native target that includes the sources phase.
        try PBXNativeTarget(
            name: "App",
            buildPhases: [sourcesPhase],
            productType: .application
        )
        .add(to: pbxProj)
        .add(to: pbxProj.rootObject)

        let mapper = PBXSourcesBuildPhaseMapper()

        // When
        let sources = try mapper.map(sourcesPhase, xcodeProj: mockProvider.xcodeProj)

        // Then
        #expect(sources.count == 1)
        let sourceFile = try #require(sources.first)
        #expect(sourceFile.path.basename == "main.swift")
        #expect(sourceFile.compilerFlags == "-DDEBUG")
    }

    @Test("Handles source files without file references gracefully")
    func testMapSourceFile_missingFileRef() throws {
        // Given
        let mockProvider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = mockProvider.xcodeProj.pbxproj

        // A build file with no file reference.
        let buildFile = PBXBuildFile()
        let sourcesPhase = PBXSourcesBuildPhase(files: [buildFile]).add(to: pbxProj)
        let target = try PBXNativeTarget.test(buildPhases: [sourcesPhase])
            .add(to: pbxProj)
            .add(to: pbxProj.rootObject)
        try mockProvider.addTargets([target])

        let mapper = PBXSourcesBuildPhaseMapper()

        // When
        let sources = try mapper.map(sourcesPhase, xcodeProj: mockProvider.xcodeProj)

        // Then
        #expect(sources.isEmpty == true) // Gracefully handled empty result.
    }

    @Test("Gracefully handles non-existent file paths for source files")
    func testMapSourceFile_unresolvableFullPath() throws {
        // Given
        // Use a provider with an invalid source directory to simulate missing files.
        let mockProvider = MockProjectProvider(
            sourceDirectory: "/invalid/Path",
            projectName: "TestProject"
        )
        let pbxProj = mockProvider.xcodeProj.pbxproj

        let fileRef = PBXFileReference(
            name: "NonExistent.swift",
            path: "NonExistent.swift"
        )
        let buildFile = PBXBuildFile(file: fileRef).add(to: pbxProj)
        let sourcesPhase = PBXSourcesBuildPhase(files: [buildFile]).add(to: pbxProj)

        try PBXNativeTarget.test(buildPhases: [sourcesPhase])
            .add(to: pbxProj)
            .add(to: pbxProj.rootObject)

        let mapper = PBXSourcesBuildPhaseMapper()

        // When
        let sources = try mapper.map(sourcesPhase, xcodeProj: mockProvider.xcodeProj)

        // Then
        #expect(sources.isEmpty == true)
    }

    @Test(
        "Correctly identifies code generation attributes for source files",
        arguments: [FileCodeGen.public, .private, .project, .disabled]
    )
    func testCodeGenAttributes(_ fileCodeGen: FileCodeGen) throws {
        // Given
        let provider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = provider.xcodeProj.pbxproj

        let fileRef = try PBXFileReference.test(name: "File.swift", path: "File.swift")
            .add(to: pbxProj)
            .addToMainGroup(in: pbxProj)

        let buildFile = PBXBuildFile(
            file: fileRef,
            settings: ["ATTRIBUTES": [fileCodeGen.rawValue]]
        ).add(to: pbxProj)

        let sourcesPhase = PBXSourcesBuildPhase(files: [buildFile]).add(to: pbxProj)
        try PBXNativeTarget.test(buildPhases: [sourcesPhase])
            .add(to: pbxProj)
            .add(to: pbxProj.rootObject)

        let mapper = PBXSourcesBuildPhaseMapper()

        // When
        let sources = try mapper.map(sourcesPhase, xcodeProj: provider.xcodeProj)

        // Then
        #expect(sources.count == 1)
        let sourceFile = try #require(sources.first)
        #expect(sourceFile.codeGen == fileCodeGen)
    }
}
