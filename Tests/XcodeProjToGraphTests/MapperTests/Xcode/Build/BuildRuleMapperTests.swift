import Testing
import XcodeGraph
import XcodeProj

@testable import TestSupport
@testable import XcodeProjToGraph  // Adjust to access BuildRuleMapper, BuildRule, etc.

struct BuildRuleMapperTests {
  let mapper = BuildRuleMapper()

  @Test func testMapBuildRulesWithKnownCompilerSpecAndFileType() async throws {
    // Using a known compiler spec from the enum, e.g. .appleClang
    let knownCompilerSpec = BuildRule.CompilerSpec.appleClang.rawValue
    let knownFileType = BuildRule.FileType.cSource.rawValue
    let projectProvider = MockProjectProvider()

    let buildRule: PBXBuildRule = PBXBuildRule.mock(
      compilerSpec: knownCompilerSpec,
      fileType: knownFileType,
      filePatterns: "*.c",
      name: "C Rule",
      outputFiles: ["$(DERIVED_FILE_DIR)/output.c.o"],
      inputFiles: ["$(SRCROOT)/main.c"],
      outputFilesCompilerFlags: ["-O2"],
      script: "echo Building C sources",
      runOncePerArchitecture: false,
      pbxProj: projectProvider.pbxProj
    )

    let target = PBXNativeTarget.mock(buildRules: [buildRule], pbxProj: projectProvider.pbxProj)
    let rules = try await mapper.mapBuildRules(target: target)

    #expect(rules.count == 1)
    let rule = rules.first
    try #require(rule != nil)
    #expect(rule?.compilerSpec.rawValue == knownCompilerSpec)
    #expect(rule?.fileType.rawValue == knownFileType)
    #expect(rule?.filePatterns == "*.c")
    #expect(rule?.name == "C Rule")
    #expect(rule?.outputFiles == ["$(DERIVED_FILE_DIR)/output.c.o"])
    #expect(rule?.inputFiles == ["$(SRCROOT)/main.c"])
    #expect(rule?.outputFilesCompilerFlags == ["-O2"])
    #expect(rule?.script == "echo Building C sources")
    #expect(rule?.runOncePerArchitecture == false)
  }

  @Test func testMapBuildRulesWithUnknownCompilerSpec() async throws {
    let projectProvider = MockProjectProvider()
    let unknownCompilerSpec = "com.apple.compilers.unknown"
    let knownFileType = "sourcecode.c.c"

    let buildRule = PBXBuildRule.mock(
      compilerSpec: unknownCompilerSpec,
      fileType: knownFileType,
      pbxProj: projectProvider.pbxProj
    )

    let target = PBXNativeTarget.mock(
      buildRules: [buildRule],
      pbxProj: projectProvider.pbxProj)
    let rules = try await mapper.mapBuildRules(target: target)

    // Unknown compiler spec means the rule should be skipped
    #expect(rules.count == 0)
  }

  @Test func testMapBuildRulesWithUnknownFileType() async throws {
    let projectProvider = MockProjectProvider()
    let knownCompilerSpec = BuildRule.CompilerSpec.appleClang.rawValue
    let unknownFileType = "sourcecode.unknown"

    let buildRule = PBXBuildRule.mock(
      compilerSpec: knownCompilerSpec,
      fileType: unknownFileType,
      pbxProj: projectProvider.pbxProj
    )

    let target = PBXNativeTarget.mock(
      buildRules: [buildRule],
      pbxProj: projectProvider.pbxProj)
    let rules = try await mapper.mapBuildRules(target: target)

    // Unknown file type means the rule should be skipped
    #expect(rules.count == 0)
  }

  @Test func testMapBuildRulesWithMixedValidAndInvalid() async throws {
    let projectProvider = MockProjectProvider()
    let knownCompilerSpec = BuildRule.CompilerSpec.appleClang.rawValue
    let knownFileType = BuildRule.FileType.cSource.rawValue
    let unknownCompilerSpec = "com.apple.compilers.unknown"
    let unknownFileType = "sourcecode.unknown"

    let validRule = PBXBuildRule.mock(
      compilerSpec: knownCompilerSpec,
      fileType: knownFileType,
      name: "Valid Rule",
      pbxProj: projectProvider.pbxProj
    )

    let invalidRuleUnknownCompiler = PBXBuildRule.mock(
      compilerSpec: unknownCompilerSpec,
      fileType: knownFileType,
      name: "Invalid Compiler",
      pbxProj: projectProvider.pbxProj
    )

    let invalidRuleUnknownFileType = PBXBuildRule.mock(
      compilerSpec: knownCompilerSpec,
      fileType: unknownFileType,
      name: "Invalid FileType",
      pbxProj: projectProvider.pbxProj
    )

    let target = PBXNativeTarget.mock(
      buildRules: [validRule, invalidRuleUnknownCompiler, invalidRuleUnknownFileType],
      pbxProj: projectProvider.pbxProj)
    let rules = try await mapper.mapBuildRules(target: target)

    // Only the valid rule should be included
    #expect(rules.count == 1)
    #expect(rules.first?.name == "Valid Rule")
  }
}
