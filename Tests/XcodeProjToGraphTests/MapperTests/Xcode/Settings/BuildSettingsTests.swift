import Path
import Testing
import XcodeGraph
import XcodeProj

@testable import TestSupport
@testable import XcodeProjToGraph

struct BuildSettingsTests {
  /// Tests that a string value is correctly extracted from build settings.
  @Test func testStringExtraction() async throws {
    let settings: [String: Any] = ["COMPILER_FLAGS": "-ObjC"]
    let value = settings.string(for: .compilerFlags)
    try #require(value != nil)
    #expect(value == "-ObjC")
  }

  /// Tests that a boolean value is correctly extracted, and invalid types return nil.
  @Test func testBoolExtraction() {
    let settings: [String: Any] = ["PRUNE": true]
    let boolValue = settings.bool(for: .prune)
    #expect(boolValue == true)

    // Test invalid type
    let invalidSettings: [String: Any] = ["PRUNE": "notABool"]
    let invalidBool = invalidSettings.bool(for: .prune)
    #expect(invalidBool == nil)
  }

  /// Tests extracting a string array from build settings.
  @Test func testStringArrayExtraction() async throws {
    let settings: [String: Any] = ["LAUNCH_ARGUMENTS": ["-enableFeature", "-verbose"]]
    let args = settings.stringArray(for: .launchArguments)
    try #require(args != nil)
    #expect(args?.count == 2)
    #expect(args?.contains("-verbose") == true)
  }

  /// Tests extracting a dictionary of strings (for environment variables).
  @Test func testStringDictExtraction() async throws {
    let settings: [String: Any] = ["ENVIRONMENT_VARIABLES": ["KEY": "VALUE"]]
    let envVars = settings.stringDict(for: .environmentVariables)
    try #require(envVars != nil)
    #expect(envVars?["KEY"] == "VALUE")
  }

  /// Tests that missing keys return nil.
  @Test func testMissingKeyReturnsNil() {
    let settings: [String: Any] = ["TAGS": "some,tags"]
    #expect(settings.string(for: .productBundleIdentifier) == nil)
    #expect(settings.bool(for: .mergeable) == nil)
  }

  /// Tests that non-string array values are coerced to strings.
  /// Example: If a setting is `[Any]` but some elements aren’t strings, they’re filtered out.
  @Test func testCoerceAnyArrayToStringArray() async throws {
    let settings: [String: Any] = ["LAUNCH_ARGUMENTS": ["-flag", 42, true]]
    let args = settings.stringArray(for: .launchArguments)
    try #require(args != nil)
    // Non-string elements (42, true) should be discarded, leaving only ["-flag"].
    #expect(args == ["-flag"])
  }
}
