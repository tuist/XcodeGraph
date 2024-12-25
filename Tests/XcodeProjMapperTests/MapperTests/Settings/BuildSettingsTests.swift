import Path
import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeProjMapper

@Suite
struct BuildSettingsTests {
    @Test("Extracts a string value from build settings")
    func testStringExtraction() throws {
        let settings: [String: Any] = ["COMPILER_FLAGS": "-ObjC"]
        let value = settings.string(for: .compilerFlags)
        try #require(value != nil)
        #expect(value == "-ObjC")
    }

    @Test("Extracts a boolean value from build settings and returns nil for invalid types")
    func testBoolExtraction() {
        let settings: [String: Any] = ["PRUNE": true]
        let boolValue = settings.bool(for: .prune)
        #expect(boolValue == true)

        // Invalid type for boolean
        let invalidSettings: [String: Any] = ["PRUNE": "notABool"]
        let invalidBool = invalidSettings.bool(for: .prune)
        #expect(invalidBool == nil)
    }

    @Test("Extracts a string array from build settings")
    func testStringArrayExtraction() throws {
        let settings: [String: Any] = ["LAUNCH_ARGUMENTS": ["-enableFeature", "-verbose"]]
        let args = settings.stringArray(for: .launchArguments)
        try #require(args != nil)
        #expect(args?.count == 2)
        #expect(args?.contains("-verbose") == true)
    }

    @Test("Extracts a dictionary of strings (e.g., environment variables) from build settings")
    func testStringDictExtraction() throws {
        let settings: [String: Any] = ["ENVIRONMENT_VARIABLES": ["KEY": "VALUE"]]
        let envVars = settings.stringDict(for: .environmentVariables)
        try #require(envVars != nil)
        #expect(envVars?["KEY"] == "VALUE")
    }

    @Test("Returns nil when keys are missing in build settings")
    func testMissingKeyReturnsNil() {
        let settings: [String: Any] = ["TAGS": "some,tags"]
        #expect(settings.string(for: .productBundleIdentifier) == nil)
        #expect(settings.bool(for: .mergeable) == nil)
    }

    @Test("Coerces any array elements to strings, discarding non-string values")
    func testCoerceAnyArrayToStringArray() throws {
        let settings: [String: Any] = ["LAUNCH_ARGUMENTS": ["-flag", 42, true]]
        let args = settings.stringArray(for: .launchArguments)
        try #require(args != nil)
        // Non-string elements are discarded, leaving only ["-flag"]
        #expect(args == ["-flag"])
    }

    @Test(
        "Extracts the SDKROOT build setting as a string",
        arguments: Platform.allCases
    )
    func testExtractSDKROOT(platform: Platform) throws {
        let settings: [String: Any] = ["SDKROOT": platform.xcodeSdkRoot]

        let sdkroot = settings.string(for: .sdkroot)
        try #require(sdkroot != nil)
        #expect(sdkroot == platform.xcodeSdkRoot)
    }
}
