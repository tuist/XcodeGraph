import Testing
import XcodeGraph

@testable import XcodeProjToGraph

@Suite
struct ConfigurationMatcherTests {
    @Test("Detects 'Debug' variants from configuration names")
    func testVariantDetectionForDebug() async throws {
        #expect(ConfigurationMatcher.variant(forName: "Debug") == .debug)
        #expect(ConfigurationMatcher.variant(forName: "development") == .debug)
        #expect(ConfigurationMatcher.variant(forName: "dev") == .debug)
    }

    @Test("Detects 'Release' variants from configuration names")
    func testVariantDetectionForRelease() async throws {
        #expect(ConfigurationMatcher.variant(forName: "Release") == .release)
        #expect(ConfigurationMatcher.variant(forName: "prod") == .release)
        #expect(ConfigurationMatcher.variant(forName: "production") == .release)
    }

    @Test("Falls back to 'Debug' variant for unrecognized configuration names")
    func testVariantFallbackToDebug() async throws {
        // Names without debug/release keywords default to .debug
        #expect(ConfigurationMatcher.variant(forName: "Staging") == .debug)
        #expect(ConfigurationMatcher.variant(forName: "CustomConfig") == .debug)
    }

    @Test("Validates configuration names based on allowed patterns")
    func testValidateConfigurationName() async throws {
        #expect(ConfigurationMatcher.validateConfigurationName("Debug") == true)
        #expect(ConfigurationMatcher.validateConfigurationName("Release") == true)

        // Invalid names: empty, whitespace, or containing spaces
        #expect(ConfigurationMatcher.validateConfigurationName("") == false)
        #expect(ConfigurationMatcher.validateConfigurationName("Debug Config") == false)
        #expect(ConfigurationMatcher.validateConfigurationName(" ") == false)
    }
}
