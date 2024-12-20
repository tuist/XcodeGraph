import Testing
import XcodeGraph
@testable import XcodeProjMapper

@Suite
struct ConfigurationMatcherTests {
    let configurationMatcher: ConfigurationMatching

    init(configurationMatcher: ConfigurationMatching = ConfigurationMatcher()) {
        self.configurationMatcher = configurationMatcher
    }

    @Test("Detects 'Debug' variants from configuration names")
    func testVariantDetectionForDebug() throws {
        #expect(configurationMatcher.variant(for: "Debug") == .debug)
        #expect(configurationMatcher.variant(for: "development") == .debug)
        #expect(configurationMatcher.variant(for: "dev") == .debug)
    }

    @Test("Detects 'Release' variants from configuration names")
    func testVariantDetectionForRelease() throws {
        #expect(configurationMatcher.variant(for: "Release") == .release)
        #expect(configurationMatcher.variant(for: "prod") == .release)
        #expect(configurationMatcher.variant(for: "production") == .release)
    }

    @Test("Falls back to 'Debug' variant for unrecognized configuration names")
    func testVariantFallbackToDebug() throws {
        #expect(configurationMatcher.variant(for: "Staging") == .debug)
        #expect(configurationMatcher.variant(for: "CustomConfig") == .debug)
    }

    @Test("Validates configuration names based on allowed patterns")
    func testValidateConfigurationName() throws {
        #expect(configurationMatcher.validateConfigurationName("Debug") == true)
        #expect(configurationMatcher.validateConfigurationName("Release") == true)

        // Invalid names: empty, whitespace, or containing spaces
        #expect(configurationMatcher.validateConfigurationName("") == false)
        #expect(configurationMatcher.validateConfigurationName("Debug Config") == false)
        #expect(configurationMatcher.validateConfigurationName(" ") == false)
    }
}
