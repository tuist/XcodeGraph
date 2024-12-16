import Testing
import TestSupport
import XcodeGraph
import XcodeProj
@testable import XcodeProjToGraph

@Suite
struct BuildPhaseMapperTests {
    @Test("Maps swift source files with compiler flags from sources phase")
    func testMapSources() async throws {
        let provider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = provider.xcodeProj.pbxproj

        let fileRef = PBXFileReference.mock(
            sourceTree: .group,
            name: "main.swift",
            path: "main.swift",
            pbxProj: pbxProj
        )
        let buildFile = PBXBuildFile.mock(
            file: fileRef, settings: ["COMPILER_FLAGS": "-DDEBUG"], pbxProj: pbxProj
        )
        let sourcesPhase = PBXSourcesBuildPhase.mock(files: [buildFile], pbxProj: pbxProj)

        let target = PBXNativeTarget.mock(
            name: "App",
            buildPhases: [sourcesPhase],
            productType: .application,
            pbxProj: pbxProj
        )
        try provider.addTargets([target])

        let mapper = BuildPhaseMapper(projectProvider: provider)
        let sources = try await mapper.mapSources(target: target)

        #expect(sources.count == 1)
        let sourceFile = try #require(sources.first)
        #expect(sourceFile.path.basename == "main.swift")
        #expect(sourceFile.compilerFlags == "-DDEBUG")
    }

    @Test("Maps resources (like xcassets) from resources phase")
    func testMapResources() async throws {
        let provider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = provider.xcodeProj.pbxproj

        let assetRef = PBXFileReference.mock(
            sourceTree: .group,
            name: "Assets.xcassets",
            path: "Assets.xcassets",
            pbxProj: pbxProj
        )
        let buildFile = PBXBuildFile.mock(file: assetRef, pbxProj: pbxProj)
        let resourcesPhase = PBXResourcesBuildPhase.mock(files: [buildFile], pbxProj: pbxProj)

        let target = PBXNativeTarget.mock(
            name: "App",
            buildPhases: [resourcesPhase],
            productType: .application,
            pbxProj: pbxProj
        )
        try provider.addTargets([target])

        let mapper = BuildPhaseMapper(projectProvider: provider)
        let resources = try await mapper.mapResources(target: target)

        #expect(resources.count == 1)
        let resource = try #require(resources.first)
        switch resource {
        case let .file(path, _, _):
            #expect(path.basename == "Assets.xcassets")
        default:
            Issue.record("Expected a file resource.")
        }
    }

    @Test("Maps frameworks from frameworks phase")
    func testMapFrameworks() async throws {
        let provider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = provider.xcodeProj.pbxproj

        let frameworkRef = PBXFileReference.mock(
            sourceTree: .group,
            name: "MyFramework.framework",
            path: "Frameworks/MyFramework.framework",
            pbxProj: pbxProj
        )
        let frameworkBuildFile = PBXBuildFile.mock(file: frameworkRef, pbxProj: pbxProj)
        let frameworksPhase = PBXFrameworksBuildPhase.mock(files: [frameworkBuildFile], pbxProj: pbxProj)

        let target = PBXNativeTarget.mock(
            name: "App",
            buildPhases: [frameworksPhase],
            productType: .application,
            pbxProj: pbxProj
        )
        try provider.addTargets([target])

        let mapper = BuildPhaseMapper(projectProvider: provider)
        let frameworks = try await mapper.mapFrameworks(target: target)

        #expect(frameworks.count == 1)
        let dependency = try #require(frameworks.first)
        #expect(dependency.name == "MyFramework")
    }

    @Test("Maps public, private, and project headers from headers phase")
    func testMapHeaders() async throws {
        let provider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = provider.xcodeProj.pbxproj

        let publicHeaderRef = PBXFileReference.mock(
            name: "PublicHeader.h", path: "Include/PublicHeader.h", pbxProj: pbxProj
        )
        let publicBuildFile = PBXBuildFile.mock(
            file: publicHeaderRef, settings: ["ATTRIBUTES": ["Public"]], pbxProj: pbxProj
        )

        let privateHeaderRef = PBXFileReference.mock(
            name: "PrivateHeader.h", path: "Include/PrivateHeader.h", pbxProj: pbxProj
        )
        let privateBuildFile = PBXBuildFile.mock(
            file: privateHeaderRef, settings: ["ATTRIBUTES": ["Private"]], pbxProj: pbxProj
        )

        let projectHeaderRef = PBXFileReference.mock(
            name: "ProjectHeader.h", path: "Include/ProjectHeader.h", pbxProj: pbxProj
        )
        let projectBuildFile = PBXBuildFile.mock(file: projectHeaderRef, pbxProj: pbxProj)

        let headersPhase = PBXHeadersBuildPhase(
            files: [publicBuildFile, privateBuildFile, projectBuildFile],
            buildActionMask: PBXBuildPhase.defaultBuildActionMask,
            runOnlyForDeploymentPostprocessing: false
        )
        pbxProj.add(object: headersPhase)

        let target = PBXNativeTarget.mock(
            name: "App",
            buildPhases: [headersPhase],
            productType: .application,
            pbxProj: pbxProj
        )
        try provider.addTargets([target])

        let mapper = BuildPhaseMapper(projectProvider: provider)
        let headers = try await mapper.mapHeaders(target: target)
        try #require(headers != nil)

        #expect(headers?.public.map(\.basename).contains("PublicHeader.h") == true)
        #expect(headers?.private.map(\.basename).contains("PrivateHeader.h") == true)
        #expect(headers?.project.map(\.basename).contains("ProjectHeader.h") == true)
    }

    @Test("Maps embedded run scripts with specified input/output paths")
    func testMapScripts() async throws {
        let provider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = provider.xcodeProj.pbxproj

        let scriptPhase = PBXShellScriptBuildPhase.mock(
            name: "Run Script",
            shellScript: "echo Hello",
            inputPaths: ["$(SRCROOT)/input.txt"],
            outputPaths: ["$(DERIVED_FILE_DIR)/output.txt"],
            pbxProj: pbxProj
        )

        let target = PBXNativeTarget.mock(
            name: "App",
            buildPhases: [scriptPhase],
            productType: .application,
            pbxProj: pbxProj
        )
        try provider.addTargets([target])

        let mapper = BuildPhaseMapper(projectProvider: provider)
        let scripts = try await mapper.mapScripts(target: target)

        #expect(scripts.count == 1)
        let script = try #require(scripts.first)
        #expect(script.name == "Run Script")
        #expect(script.script == .embedded("echo Hello"))
        #expect(script.inputPaths == ["$(SRCROOT)/input.txt"])
        #expect(script.outputPaths == ["$(DERIVED_FILE_DIR)/output.txt"])
    }

    @Test("Maps copy files actions, verifying code-sign-on-copy attributes")
    func testMapCopyFiles() async throws {
        let provider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = provider.xcodeProj.pbxproj

        let fileRef = PBXFileReference.mock(
            sourceTree: .group, name: "MyLibrary.dylib", path: "MyLibrary.dylib", pbxProj: pbxProj
        )
        let buildFile = PBXBuildFile.mock(
            file: fileRef, settings: ["ATTRIBUTES": ["CodeSignOnCopy"]], pbxProj: pbxProj
        )
        let copyFilesPhase = PBXCopyFilesBuildPhase.mock(
            name: "Embed Libraries",
            dstPath: "Libraries",
            dstSubfolderSpec: .frameworks,
            files: [buildFile],
            pbxProj: pbxProj
        )

        let target = PBXNativeTarget.mock(
            name: "App",
            buildPhases: [copyFilesPhase],
            productType: .application,
            pbxProj: pbxProj
        )
        try provider.addTargets([target])

        let mapper = BuildPhaseMapper(projectProvider: provider)
        let copyActions = try await mapper.mapCopyFiles(target: target)

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

    @Test("Maps CoreData models from version groups within resources phase")
    func testMapCoreDataModels() async throws {
        let provider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = provider.xcodeProj.pbxproj

        let versionChildRef = PBXFileReference.mock(
            name: "Model.xcdatamodel",
            path: "Model.xcdatamodel",
            pbxProj: pbxProj
        )
        let versionGroup = XCVersionGroup.mock(
            currentVersion: versionChildRef,
            children: [versionChildRef],
            path: "Model.xcdatamodeld",
            sourceTree: .group,
            versionGroupType: "wrapper.xcdatamodel",
            name: "Model.xcdatamodeld",
            pbxProj: pbxProj
        )

        let buildFile = PBXBuildFile.mock(file: versionGroup, pbxProj: pbxProj)
        let resourcesPhase = PBXResourcesBuildPhase.mock(files: [buildFile], pbxProj: pbxProj)

        let target = PBXNativeTarget.mock(
            name: "App",
            buildPhases: [resourcesPhase],
            productType: .application,
            pbxProj: pbxProj
        )
        try provider.addTargets([target])

        let mapper = BuildPhaseMapper(projectProvider: provider)
        let models = try await mapper.mapCoreDataModels(target: target)

        #expect(models.count == 1)
        let model = try #require(models.first)
        #expect(model.path.basename == "Model.xcdatamodeld")
        #expect(model.versions.count == 1)
        #expect(model.currentVersion.contains("Model.xcdatamodel") == true)
    }

    @Test("Maps raw script build phases not covered by other categories")
    func testMapRawScriptBuildPhases() async throws {
        let provider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = provider.xcodeProj.pbxproj

        let scriptPhase = PBXShellScriptBuildPhase.mock(name: "Test Script", pbxProj: pbxProj)
        let target = PBXNativeTarget.mock(
            name: "App",
            buildPhases: [scriptPhase],
            productType: .application,
            pbxProj: pbxProj
        )
        try provider.addTargets([target])

        let mapper = BuildPhaseMapper(projectProvider: provider)
        let rawPhases = try await mapper.mapRawScriptBuildPhases(target: target)

        #expect(rawPhases.count == 1)
        let rawPhase = try #require(rawPhases.first)
        #expect(rawPhase.name == "Test Script")
    }

    @Test("Identifies additional files not included in any build phase")
    func testMapAdditionalFiles() async throws {
        let provider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = provider.xcodeProj.pbxproj

        // Add two extra files at the root of the main group
        if let project = pbxProj.projects.first, let mainGroup = project.mainGroup {
            let fileRef1 = PBXFileReference.mock(name: "Extra1.txt", path: "Extra1.txt", pbxProj: pbxProj)
            let fileRef2 = PBXFileReference.mock(name: "Extra2.json", path: "Extra2.json", pbxProj: pbxProj)
            mainGroup.children.append(contentsOf: [fileRef1, fileRef2])
        }

        let target = PBXNativeTarget.mock(
            name: "App",
            buildPhases: [],
            productType: .application,
            pbxProj: pbxProj
        )
        try provider.addTargets([target])

        let mapper = BuildPhaseMapper(projectProvider: provider)
        let additionalFiles = try await mapper.mapAdditionalFiles(target: target)

        #expect(additionalFiles.count == 2)
        let names = additionalFiles.map(\.path.basename)
        #expect(names.contains("Extra1.txt") == true)
        #expect(names.contains("Extra2.json") == true)
    }

    @Test("Handles source files without file references gracefully")
    func testMapSourceFile_missingFileRef() async throws {
        let provider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = provider.xcodeProj.pbxproj

        // Build file without a file ref
        let buildFile = PBXBuildFile()

        let sourcesPhase = PBXSourcesBuildPhase.mock(files: [buildFile], pbxProj: pbxProj)
        let target = PBXNativeTarget.mock(buildPhases: [sourcesPhase], pbxProj: pbxProj)
        try provider.addTargets([target])

        let mapper = BuildPhaseMapper(projectProvider: provider)
        let sources = try await mapper.mapSources(target: target)
        #expect(sources.isEmpty == true) // Gracefully handled
    }

    @Test("Gracefully handles non-existent file paths for source files")
    func testMapSourceFile_unresolvableFullPath() async throws {
        // Special case: use a provider with invalid sourceDirectory to simulate missing files
        let mockProvider = MockProjectProvider(
            sourceDirectory: "/invalid/Path",
            projectName: "TestProject"
        )
        let pbxProj = mockProvider.xcodeProj.pbxproj

        let fileRef = PBXFileReference(
            name: "NonExistent.swift",
            path: "NonExistent.swift"
        )
        let buildFile = PBXBuildFile.mock(file: fileRef, pbxProj: pbxProj)
        let sourcesPhase = PBXSourcesBuildPhase.mock(files: [buildFile], pbxProj: pbxProj)
        let target = PBXNativeTarget.mock(buildPhases: [sourcesPhase], pbxProj: pbxProj)

        let mapper = BuildPhaseMapper(projectProvider: mockProvider)
        let sources = try await mapper.mapSources(target: target)
        #expect(sources.isEmpty == true)
    }

    @Test("Maps localized variant groups from resources")
    func testMapVariantGroup() async throws {
        let provider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = provider.xcodeProj.pbxproj

        let fileRef1 = PBXFileReference.mock(
            name: "Localizable.strings",
            path: "en.lproj/Localizable.strings",
            pbxProj: pbxProj,
            addToMainGroup: false
        )
        let fileRef2 = PBXFileReference.mock(
            name: "Localizable.strings",
            path: "fr.lproj/Localizable.strings",
            pbxProj: pbxProj,
            addToMainGroup: false
        )
        let variantGroup = PBXVariantGroup.mockVariant(
            children: [fileRef1, fileRef2],
            pbxProj: pbxProj,
            addToMainGroup: false
        )

        // Add variant group to main group for correct path resolution
        if let project = pbxProj.projects.first, let mainGroup = project.mainGroup {
            mainGroup.children.append(variantGroup)
        }

        let buildFile = PBXBuildFile.mock(file: variantGroup, pbxProj: pbxProj)
        let resourcesPhase = PBXResourcesBuildPhase.mock(files: [buildFile], pbxProj: pbxProj)
        let target = PBXNativeTarget.mock(buildPhases: [resourcesPhase], pbxProj: pbxProj)
        try provider.addTargets([target])

        let mapper = BuildPhaseMapper(projectProvider: provider)
        let resources = try await mapper.mapResources(target: target)

        #expect(resources.count == 2)
        #expect(resources.first?.path.basename == "Localizable.strings")
    }

    @Test("Recursively collects files from nested groups and variant groups")
    func testCollectFiles_withNestedGroups() async throws {
        let provider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = provider.xcodeProj.pbxproj

        let fileRef1 = PBXFileReference.mock(name: "RootFile.txt", path: "RootFile.txt", pbxProj: pbxProj, addToMainGroup: false)
        let subfileRef = PBXFileReference.mock(name: "Subfile.txt", path: "Subfile.txt", pbxProj: pbxProj, addToMainGroup: false)
        let subgroup = PBXGroup.mock(children: [subfileRef], name: "Subgroup", path: "Subgroup", pbxProj: pbxProj)

        let vfileRef = PBXFileReference.mock(
            name: "VariantFile.strings",
            path: "en.lproj/VariantFile.strings",
            pbxProj: pbxProj,
            addToMainGroup: false
        )
        let variantGroup = PBXVariantGroup.mock(children: [vfileRef], pbxProj: pbxProj)
        subgroup.children.append(variantGroup)

        if let project = pbxProj.projects.first,
           let mainGroup = project.mainGroup
        {
            mainGroup.children.append(fileRef1)
            mainGroup.children.append(subgroup)
        }

        let target = PBXNativeTarget.mock(buildPhases: [], pbxProj: pbxProj)
        try provider.addTargets([target])

        let mapper = BuildPhaseMapper(projectProvider: provider)
        let additionalFiles = try await mapper.mapAdditionalFiles(target: target)

        #expect(additionalFiles.count == 3)
        let names = additionalFiles.map(\.path.basename).sorted()
        #expect(names == ["RootFile.txt", "Subfile.txt", "VariantFile.strings"].sorted())
    }

    @Test(
        "Correctly identifies code generation attributes for source files",
        arguments: [FileCodeGen.public, .private, .project, .disabled]
    )
    func testCodeGenAttributes(_ fileCodeGen: FileCodeGen) async throws {
        let provider: MockProjectProvider = .makeBasicProjectProvider()
        let pbxProj = provider.xcodeProj.pbxproj

        let fileRef = PBXFileReference.mock(name: "File.swift", path: "File.swift", pbxProj: pbxProj)
        let buildFile = PBXBuildFile.mock(file: fileRef, settings: ["ATTRIBUTES": [fileCodeGen.rawValue]], pbxProj: pbxProj)
        let sourcesPhase = PBXSourcesBuildPhase.mock(files: [buildFile], pbxProj: pbxProj)
        let target = PBXNativeTarget.mock(buildPhases: [sourcesPhase], pbxProj: pbxProj)
        try provider.addTargets([target])

        let mapper = BuildPhaseMapper(projectProvider: provider)
        let sources = try await mapper.mapSources(target: target)

        #expect(sources.count == 1)
        let sourceFile = try #require(sources.first)
        #expect(sourceFile.codeGen == fileCodeGen)
    }
}
