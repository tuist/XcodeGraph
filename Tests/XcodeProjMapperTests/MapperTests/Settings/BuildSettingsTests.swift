import Path
import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeProjMapper

@Suite
struct BuildSettingsTests {
    @Test("Extracts a string value from build settings")
    func testStringExtraction() throws {
        // Given
        let settings: [String: Any] = ["COMPILER_FLAGS": "-ObjC"]

        // When
        let value = settings.string(for: .compilerFlags)

        // Then
        try #require(value != nil)
        #expect(value == "-ObjC")
    }

    @Test("Extracts a boolean value from build settings and returns nil for invalid types")
    func testBoolExtraction() {
        // Given
        let settings: [String: Any] = ["PRUNE": true]
        let invalidSettings: [String: Any] = ["PRUNE": "notABool"]

        // When
        let boolValue = settings.bool(for: .prune)
        let invalidBool = invalidSettings.bool(for: .prune)

        // Then
        #expect(boolValue == true)
        #expect(invalidBool == nil)
    }

    @Test("Extracts a string array from build settings")
    func testStringArrayExtraction() throws {
        // Given
        let settings: [String: Any] = ["LAUNCH_ARGUMENTS": ["-enableFeature", "-verbose"]]

        // When
        let args = settings.stringArray(for: .launchArguments)

        // Then
        try #require(args != nil)
        #expect(args?.count == 2)
        #expect(args?.contains("-verbose") == true)
    }

    @Test("Extracts a dictionary of strings (e.g., environment variables) from build settings")
    func testStringDictExtraction() throws {
        // Given
        let settings: [String: Any] = ["ENVIRONMENT_VARIABLES": ["KEY": "VALUE"]]

        // When
        let envVars = settings.stringDict(for: .environmentVariables)

        // Then
        try #require(envVars != nil)
        #expect(envVars?["KEY"] == "VALUE")
    }

    @Test("Returns nil when keys are missing in build settings")
    func testMissingKeyReturnsNil() {
        // Given
        let settings: [String: Any] = ["TAGS": "some,tags"]

        // When / Then
        // No key for productBundleIdentifier or mergeable, so returns nil
        #expect(settings.string(for: .productBundleIdentifier) == nil)
        #expect(settings.bool(for: .mergeable) == nil)
    }

    @Test("Coerces any array elements to strings, discarding non-string values")
    func testCoerceAnyArrayToStringArray() throws {
        // Given
        let settings: [String: Any] = ["LAUNCH_ARGUMENTS": ["-flag", 42, true]]

        // When
        let args = settings.stringArray(for: .launchArguments)

        // Then
        try #require(args != nil)
        // Non-string elements are discarded, leaving only ["-flag"]
        #expect(args == ["-flag"])
    }

    @Test(
        "Extracts the SDKROOT build setting as a string",
        arguments: Platform.allCases
    )
    func testExtractSDKROOT(platform: Platform) throws {
        // Given
        let settings: [String: Any] = ["SDKROOT": platform.xcodeSdkRoot]

        // When
        let sdkroot = settings.string(for: .sdkroot)

        // Then
        try #require(sdkroot != nil)
        #expect(sdkroot == platform.xcodeSdkRoot)
    }
}
