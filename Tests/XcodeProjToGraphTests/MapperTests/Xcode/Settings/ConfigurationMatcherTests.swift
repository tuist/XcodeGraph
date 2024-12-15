import Testing
import XcodeGraph

@testable import XcodeProjToGraph

struct ConfigurationMatcherTests {
    @Test func testVariantDetectionForDebug() async throws {
        #expect(ConfigurationMatcher.variant(forName: "Debug") == .debug)
        #expect(ConfigurationMatcher.variant(forName: "development") == .debug)
        #expect(ConfigurationMatcher.variant(forName: "dev") == .debug)
    }

    @Test func testVariantDetectionForRelease() async throws {
        #expect(ConfigurationMatcher.variant(forName: "Release") == .release)
        #expect(ConfigurationMatcher.variant(forName: "prod") == .release)
        #expect(ConfigurationMatcher.variant(forName: "production") == .release)
    }

    @Test func testVariantFallbackToDebug() async throws {
        // Names that don't match debug/release keywords should fall back to debug
        #expect(ConfigurationMatcher.variant(forName: "Staging") == .debug)
        #expect(ConfigurationMatcher.variant(forName: "CustomConfig") == .debug)
    }

    @Test func testValidateConfigurationName() async throws {
        #expect(ConfigurationMatcher.validateConfigurationName("Debug") == true)
        #expect(ConfigurationMatcher.validateConfigurationName("Release") == true)

        // Invalid names: empty, whitespace, or containing spaces
        #expect(ConfigurationMatcher.validateConfigurationName("") == false)
        #expect(ConfigurationMatcher.validateConfigurationName("Debug Config") == false)
        #expect(ConfigurationMatcher.validateConfigurationName(" ") == false)
    }
}
