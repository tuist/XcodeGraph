import Testing
import XcodeGraph
import XcodeProj

@testable import TestSupport
@testable import XcodeProjToGraph

struct BuildPhaseMapperTests {
  @Test func testMapSources() async throws {
    let mockProvider = MockProjectProvider(
      sourceDirectory: "/tmp/TestProject",
      projectName: "TestProject"
    )
    let pbxProj = mockProvider.xcodeProj.pbxproj

    let fileRef = PBXFileReference.mock(
      sourceTree: .group,
      name: "main.swift",
      path: "main.swift",
      pbxProj: pbxProj
    )

    let buildFile = PBXBuildFile.mock(
      file: fileRef, settings: ["COMPILER_FLAGS": "-DDEBUG"], pbxProj: pbxProj)
    let sourcesPhase = PBXSourcesBuildPhase.mock(files: [buildFile], pbxProj: pbxProj)

    let target = PBXNativeTarget.mock(
      name: "App",
      buildConfigurationList: nil,
      buildRules: [],
      buildPhases: [sourcesPhase],
      dependencies: [],
      productType: .application,
      pbxProj: pbxProj
    )

    if let project = pbxProj.projects.first {
      project.targets.append(target)
    }

    let mapper = BuildPhaseMapper(projectProvider: mockProvider)
    let sources = try await mapper.mapSources(target: target)

    #expect(sources.count == 1)
    let sourceFile = sources.first
    try #require(sourceFile != nil)
    #expect(sourceFile?.path.basename == "main.swift")
    #expect(sourceFile?.compilerFlags == "-DDEBUG")
  }

  @Test func testMapResources() async throws {
    let mockProvider = MockProjectProvider(
      sourceDirectory: "/tmp/TestProject",
      projectName: "TestProject"
    )
    let pbxProj = mockProvider.xcodeProj.pbxproj

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
      buildConfigurationList: nil,
      buildRules: [],
      buildPhases: [resourcesPhase],
      dependencies: [],
      productType: .application,
      pbxProj: pbxProj
    )

    if let project = pbxProj.projects.first {
      project.targets.append(target)
    }

    let mapper = BuildPhaseMapper(projectProvider: mockProvider)
    let resources = try await mapper.mapResources(target: target)
    #expect(resources.count == 1)
    let resource = resources.first
    try #require(resource != nil)
    switch resource! {
    case .file(let path, _, _):
      #expect(path.basename == "Assets.xcassets")
    default:
      Issue.record("Expected a file resource.")
    }
  }

  @Test func testMapFrameworks() async throws {
    let mockProvider = MockProjectProvider(
      sourceDirectory: "/tmp/TestProject",
      projectName: "TestProject"
    )
    let pbxProj = mockProvider.xcodeProj.pbxproj

    // Create a framework file reference
    let frameworkRef = PBXFileReference.mock(
      sourceTree: .group,
      name: "MyFramework.framework",
      path: "Frameworks/MyFramework.framework",
      pbxProj: pbxProj
    )

    let frameworkBuildFile = PBXBuildFile.mock(file: frameworkRef, pbxProj: pbxProj)
    let frameworksPhase = PBXFrameworksBuildPhase.mock(
      files: [frameworkBuildFile], pbxProj: pbxProj)

    let target = PBXNativeTarget.mock(
      name: "App",
      buildConfigurationList: nil,
      buildRules: [],
      buildPhases: [frameworksPhase],
      dependencies: [],
      productType: .application,
      pbxProj: pbxProj
    )

    if let project = pbxProj.projects.first {
      project.targets.append(target)
    }

    let mapper = BuildPhaseMapper(projectProvider: mockProvider)
    let frameworks = try await mapper.mapFrameworks(target: target)
    #expect(frameworks.count == 1)
    let dependency = frameworks.first
    try #require(dependency != nil)
    #expect(dependency?.name == "MyFramework")
  }

  @Test func testMapHeaders() async throws {
    let mockProvider = MockProjectProvider(
      sourceDirectory: "/tmp/TestProject",
      projectName: "TestProject"
    )
    let pbxProj = mockProvider.xcodeProj.pbxproj

    // Public header
    let publicHeaderRef = PBXFileReference.mock(
      name: "PublicHeader.h",
      path: "Include/PublicHeader.h",
      pbxProj: pbxProj
    )
    let publicBuildFile = PBXBuildFile.mock(
      file: publicHeaderRef, settings: ["ATTRIBUTES": ["Public"]], pbxProj: pbxProj)

    // Private header
    let privateHeaderRef = PBXFileReference.mock(
      name: "PrivateHeader.h",
      path: "Include/PrivateHeader.h",
      pbxProj: pbxProj
    )
    let privateBuildFile = PBXBuildFile.mock(
      file: privateHeaderRef, settings: ["ATTRIBUTES": ["Private"]], pbxProj: pbxProj)

    // Project header (no attributes)
    let projectHeaderRef = PBXFileReference.mock(
      name: "ProjectHeader.h",
      path: "Include/ProjectHeader.h",
      pbxProj: pbxProj
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
      buildConfigurationList: nil,
      buildRules: [],
      buildPhases: [headersPhase],
      dependencies: [],
      productType: .application,
      pbxProj: pbxProj
    )

    if let project = pbxProj.projects.first {
      project.targets.append(target)
    }

    let mapper = BuildPhaseMapper(projectProvider: mockProvider)
    let headers = try await mapper.mapHeaders(target: target)
    try #require(headers != nil)
    #expect(headers?.public.map(\.basename).contains("PublicHeader.h") == true)
    #expect(headers?.private.map(\.basename).contains("PrivateHeader.h") == true)
    #expect(headers?.project.map(\.basename).contains("ProjectHeader.h") == true)
  }

  @Test func testMapScripts() async throws {
    let mockProvider = MockProjectProvider(
      sourceDirectory: "/tmp/TestProject",
      projectName: "TestProject"
    )
    let pbxProj = mockProvider.xcodeProj.pbxproj

    let scriptPhase = PBXShellScriptBuildPhase.mock(
      name: "Run Script",
      shellScript: "echo Hello",
      inputPaths: ["$(SRCROOT)/input.txt"],
      outputPaths: ["$(DERIVED_FILE_DIR)/output.txt"],
      pbxProj: pbxProj
    )

    let target = PBXNativeTarget.mock(
      name: "App",
      buildConfigurationList: nil,
      buildRules: [],
      buildPhases: [scriptPhase],
      dependencies: [],
      productType: .application,
      pbxProj: pbxProj
    )

    if let project = pbxProj.projects.first {
      project.targets.append(target)
    }

    let mapper = BuildPhaseMapper(projectProvider: mockProvider)
    let scripts = try await mapper.mapScripts(target: target)
    #expect(scripts.count == 1)
    let script = scripts.first
    try #require(script != nil)
    #expect(script?.name == "Run Script")
    #expect(script?.script == .embedded("echo Hello"))
    #expect(script?.inputPaths == ["$(SRCROOT)/input.txt"])
    #expect(script?.outputPaths == ["$(DERIVED_FILE_DIR)/output.txt"])
  }

  @Test func testMapCopyFiles() async throws {
    let mockProvider = MockProjectProvider(
      sourceDirectory: "/tmp/TestProject",
      projectName: "TestProject"
    )
    let pbxProj = mockProvider.xcodeProj.pbxproj

    let fileRef = PBXFileReference.mock(
      sourceTree: .group,
      name: "MyLibrary.dylib",
      path: "MyLibrary.dylib",
      pbxProj: pbxProj
    )
    // Setting an attribute for code sign on copy
    let buildFile = PBXBuildFile.mock(
      file: fileRef, settings: ["ATTRIBUTES": ["CodeSignOnCopy"]], pbxProj: pbxProj)

    let copyFilesPhase = PBXCopyFilesBuildPhase.mock(
      name: "Embed Libraries",
      dstPath: "Libraries",
      dstSubfolderSpec: .frameworks,
      files: [buildFile],
      pbxProj: pbxProj
    )

    let target = PBXNativeTarget.mock(
      name: "App",
      buildConfigurationList: nil,
      buildRules: [],
      buildPhases: [copyFilesPhase],
      dependencies: [],
      productType: .application,
      pbxProj: pbxProj
    )
    if let project = pbxProj.projects.first {
      project.targets.append(target)
    }

    let mapper = BuildPhaseMapper(projectProvider: mockProvider)
    let copyActions = try await mapper.mapCopyFiles(target: target)
    #expect(copyActions.count == 1)
    let action = copyActions.first
    try #require(action != nil)
    #expect(action?.name == "Embed Libraries")
    #expect(action?.destination == .frameworks)
    #expect(action?.subpath == "Libraries")
    #expect(action?.files.count == 1)
    let fileAction = action?.files.first
    try #require(fileAction != nil)
    #expect(fileAction?.codeSignOnCopy == true)
    #expect(fileAction?.path.basename == "MyLibrary.dylib")
  }

  @Test func testMapCoreDataModels() async throws {
    let mockProvider = MockProjectProvider(
      sourceDirectory: "/tmp/TestProject",
      projectName: "TestProject"
    )
    let pbxProj = mockProvider.xcodeProj.pbxproj

    // Create a core data model version group
    let versionChildRef = PBXFileReference.mock(
      name: "Model.xcdatamodel", path: "Model.xcdatamodel", pbxProj: pbxProj)

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
      buildConfigurationList: nil,
      buildRules: [],
      buildPhases: [resourcesPhase],
      dependencies: [],
      productType: .application,
      pbxProj: pbxProj
    )

    if let project = pbxProj.projects.first {
      project.targets.append(target)
    }

    let mapper = BuildPhaseMapper(projectProvider: mockProvider)
    let models = try await mapper.mapCoreDataModels(target: target)
    #expect(models.count == 1)
    let model = models.first
    try #require(model != nil)
    #expect(model?.path.basename == "Model.xcdatamodeld")
    #expect(model?.versions.count == 1)
    #expect(model?.currentVersion.contains("Model.xcdatamodel") == true)
  }

  @Test func testMapRawScriptBuildPhases() async throws {
    let mockProvider = MockProjectProvider(
      sourceDirectory: "/tmp/TestProject",
      projectName: "TestProject"
    )
    let pbxProj = mockProvider.xcodeProj.pbxproj

    let frameworksPhase = PBXShellScriptBuildPhase.mock(name: "Test Script", pbxProj: pbxProj)

    let target = PBXNativeTarget.mock(
      name: "App",
      buildConfigurationList: nil,
      buildRules: [],
      buildPhases: [frameworksPhase],
      dependencies: [],
      productType: .application,
      pbxProj: pbxProj
    )

    if let project = pbxProj.projects.first {
      project.targets.append(target)
    }

    let mapper = BuildPhaseMapper(projectProvider: mockProvider)
    let rawPhases = try await mapper.mapRawScriptBuildPhases(target: target)
    #expect(rawPhases.count == 1)
    let rawPhase = rawPhases.first
    try #require(rawPhase != nil)
    #expect(rawPhase?.name == "Test Script")
  }

  @Test func testMapAdditionalFiles() async throws {
    let mockProvider = MockProjectProvider(
      sourceDirectory: "/tmp/TestProject",
      projectName: "TestProject"
    )
    let pbxProj = mockProvider.xcodeProj.pbxproj

    // Add files to main group that are not referenced by any build phase
    if let project = pbxProj.projects.first,
      let mainGroup = project.mainGroup
    {
      let fileRef1 = PBXFileReference.mock(name: "Extra1.txt", path: "Extra1.txt", pbxProj: pbxProj)
      let fileRef2 = PBXFileReference.mock(
        name: "Extra2.json", path: "Extra2.json", pbxProj: pbxProj)
      mainGroup.children.append(fileRef1)
      mainGroup.children.append(fileRef2)
    }

    // Create a target that doesn't reference these files in build phases
    let target = PBXNativeTarget.mock(
      name: "App",
      buildConfigurationList: nil,
      buildRules: [],
      buildPhases: [],
      dependencies: [],
      productType: .application,
      pbxProj: pbxProj
    )

    if let project = pbxProj.projects.first {
      project.targets.append(target)
    }

    let mapper = BuildPhaseMapper(projectProvider: mockProvider)
    let additionalFiles = try await mapper.mapAdditionalFiles(target: target)
    #expect(additionalFiles.count == 2)
    let names = additionalFiles.map { $0.path.basename }
    #expect(names.contains("Extra1.txt") == true)
    #expect(names.contains("Extra2.json") == true)
  }

  @Test func testMapSourceFile_missingFileRef() async throws {
    let mockProvider = MockProjectProvider(
      sourceDirectory: "/tmp/TestProject",
      projectName: "TestProject"
    )
    let pbxProj = mockProvider.xcodeProj.pbxproj

    // Create a build file with no file reference
    let buildFile = PBXBuildFile()
    // E.g. don't set `file` property, or fileRef is nil by default in your mock initializer.

    let mapper = BuildPhaseMapper(projectProvider: mockProvider)
    let _ = try await mapper.mapSources(
      target: PBXNativeTarget.mock(buildPhases: [], pbxProj: pbxProj))
    // Since no sources phase or buildFile with a fileRef is provided, add one manually:
    // Actually, let's simulate calling mapSourceFile directly if possible:
    // If it's private, we can create a scenario where mapSources includes that buildFile.
    // Create a sources phase to include this buildFile
    let sourcesPhase = PBXSourcesBuildPhase.mock(files: [buildFile], pbxProj: pbxProj)
    let target = PBXNativeTarget.mock(buildPhases: [sourcesPhase], pbxProj: pbxProj)

    let sources = try await mapper.mapSources(target: target)
    // Expect no crash and empty array since fileRef is nil
    #expect(sources.isEmpty == true)
  }

  @Test func testMapSourceFile_unresolvableFullPath() async throws {
    let mockProvider = MockProjectProvider(
      sourceDirectory: "/invalid/Path",
      projectName: "TestProject"
    )
    let pbxProj = mockProvider.xcodeProj.pbxproj

    let fileRef = PBXFileReference(
      name: "NonExistent.swift",
      path: "NonExistent.swift"
        // This path won't exist relative to /invalid/Path
    )
    let buildFile = PBXBuildFile.mock(file: fileRef, pbxProj: pbxProj)
    let sourcesPhase = PBXSourcesBuildPhase.mock(files: [buildFile], pbxProj: pbxProj)
    let target = PBXNativeTarget.mock(buildPhases: [sourcesPhase], pbxProj: pbxProj)

    let mapper = BuildPhaseMapper(projectProvider: mockProvider)
    let sources = try await mapper.mapSources(target: target)
    // Expect empty because fullPath could not be resolved
    #expect(sources.isEmpty == true)
  }

//  @Test func testMapVariantGroup() async throws {
//    let mockProvider = MockProjectProvider(
//      sourceDirectory: "/tmp/TestProject",
//      projectName: "TestProject"
//    )
//    let pbxProj = mockProvider.xcodeProj.pbxproj
//
//    // Create file references for localized resources, but don't auto-add them to main group
//    let fileRef1 = PBXFileReference.mock(
//      name: "Localizable.strings",
//      path: "en.lproj/Localizable.strings",
//      pbxProj: pbxProj,
//      addToMainGroup: false
//    )
//    let fileRef2 = PBXFileReference.mock(
//      name: "Localizable.strings",
//      path: "fr.lproj/Localizable.strings",
//      pbxProj: pbxProj,
//      addToMainGroup: false
//    )
//
//    // Create variant group without auto-adding it to the main group
//    let variantGroup = PBXVariantGroup.mockVariant(
//      children: [fileRef1, fileRef2],
//      pbxProj: pbxProj,
//      addToMainGroup: false
//    )
//
//    // Manually add the variant group to the main group for proper path resolution
//    if let project = pbxProj.projects.first, let mainGroup = project.mainGroup {
//      mainGroup.children.append(variantGroup)
//    }
//
//    let buildFile = PBXBuildFile.mock(file: variantGroup, pbxProj: pbxProj)
//    let resourcesPhase = PBXResourcesBuildPhase.mock(files: [buildFile], pbxProj: pbxProj)
//    let target = PBXNativeTarget.mock(
//      buildPhases: [resourcesPhase],
//      pbxProj: pbxProj
//    )
//
//    let mapper = BuildPhaseMapper(projectProvider: mockProvider)
//    let resources = try await mapper.mapResources(target: target)
//
//    #expect(resources.count == 2)
//    #expect(resources.first?.path.basename == "Localizable.strings")
//  }

  @Test func testCollectFiles_withNestedGroups() async throws {
    let mockProvider = MockProjectProvider(
      sourceDirectory: "/tmp/TestProject",
      projectName: "TestProject"
    )
    let pbxProj = mockProvider.xcodeProj.pbxproj

    // Create file references at various levels
    let fileRef1 = PBXFileReference.mock(
      name: "RootFile.txt", path: "RootFile.txt", pbxProj: pbxProj, addToMainGroup: false)

    let subfileRef = PBXFileReference.mock(
      name: "Subfile.txt",
      path: "Subfile.txt",
      pbxProj: pbxProj,
      addToMainGroup: false
    )
    let subgroup = PBXGroup.mock(
      children: [subfileRef], name: "Subgroup", path: "Subgroup", pbxProj: pbxProj)

    // Variant group inside subgroup
    let vfileRef = PBXFileReference.mock(
      name: "VariantFile.strings", path: "en.lproj/VariantFile.strings", pbxProj: pbxProj,
      addToMainGroup: false)
    let variantGroup = PBXVariantGroup.mock(children: [vfileRef], pbxProj: pbxProj)
    subgroup.children.append(variantGroup)

    if let project = pbxProj.projects.first,
      let mainGroup = project.mainGroup
    {
      mainGroup.children.append(fileRef1)
      mainGroup.children.append(subgroup)
    }

    let mapper = BuildPhaseMapper(projectProvider: mockProvider)

    let target = PBXNativeTarget.mock(buildPhases: [], pbxProj: pbxProj)
    if let project = pbxProj.projects.first {
      project.targets.append(target)
    }

    let additionalFiles = try await mapper.mapAdditionalFiles(target: target)
    // Expect 3 files: RootFile.txt, Subfile.txt, VariantFile.strings
    #expect(additionalFiles.count == 3)
    let names = additionalFiles.map { $0.path.basename }
    #expect(names.sorted() == ["RootFile.txt", "Subfile.txt", "VariantFile.strings"].sorted())

  }

  /// Validates all workspace fixtures.
  @Test(arguments: [FileCodeGen.public, .private, .project, .disabled])
  func testCodeGenAttributes(_ fileCodeGen: FileCodeGen) async throws {
    let mockProvider = MockProjectProvider(
      sourceDirectory: "/tmp/TestProject",
      projectName: "TestProject"
    )
    let pbxProj = mockProvider.xcodeProj.pbxproj

    let fileRef = PBXFileReference.mock(name: "File.swift", path: "File.swift", pbxProj: pbxProj)
    let buildFile = PBXBuildFile.mock(
      file: fileRef, settings: ["ATTRIBUTES": [fileCodeGen.rawValue]], pbxProj: pbxProj)
    let sourcesPhase = PBXSourcesBuildPhase.mock(files: [buildFile], pbxProj: pbxProj)
    let target = PBXNativeTarget.mock(buildPhases: [sourcesPhase], pbxProj: pbxProj)
    if let project = pbxProj.projects.first {
      project.targets.append(target)
    }

    let mapper = BuildPhaseMapper(projectProvider: mockProvider)
    let sources = try await mapper.mapSources(target: target)
    #expect(sources.count == 1)
    let sourceFile = sources.first
    try #require(sourceFile != nil)
    #expect(sourceFile?.codeGen == fileCodeGen)
  }

}
