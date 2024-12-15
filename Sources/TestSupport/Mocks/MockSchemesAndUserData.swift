import Foundation
import Path
import XcodeGraph
@testable @preconcurrency import XcodeProj

extension XCScheme.TestableReference {
    public static func mock(
        skipped: Bool,
        parallelization: XCScheme.TestParallelization = .none,
        randomExecutionOrdering: Bool = false,
        buildableReference: XCScheme.BuildableReference,
        locationScenarioReference: XCScheme.LocationScenarioReference? = nil,
        skippedTests: [XCScheme.TestItem] = [],
        selectedTests: [XCScheme.TestItem] = [],
        useTestSelectionWhitelist: Bool? = nil
    ) -> XCScheme.TestableReference {
        XCScheme.TestableReference(
            skipped: skipped,
            parallelization: parallelization,
            randomExecutionOrdering: randomExecutionOrdering,
            buildableReference: buildableReference,
            locationScenarioReference: locationScenarioReference,
            skippedTests: skippedTests,
            selectedTests: selectedTests,
            useTestSelectionWhitelist: useTestSelectionWhitelist
        )
    }
}

extension XCScheme {
    public static func mock(
        name: String = "DefaultScheme",
        buildAction: BuildAction? = nil,
        testAction: TestAction? = nil,
        launchAction: LaunchAction? = nil,
        archiveAction: ArchiveAction? = nil,
        profileAction: ProfileAction? = nil,
        analyzeAction: AnalyzeAction? = nil,
        wasCreatedForAppExtension: Bool? = nil
    ) -> XCScheme {
        XCScheme(
            name: name,
            lastUpgradeVersion: "1.3",
            version: "1.3",
            buildAction: buildAction,
            testAction: testAction,
            launchAction: launchAction,
            profileAction: profileAction,
            analyzeAction: analyzeAction,
            archiveAction: archiveAction,
            wasCreatedForAppExtension: wasCreatedForAppExtension
        )
    }
}

extension XCUserData {
    public static func mock(
        userName: String = "user",
        schemes: [XCScheme] = [],
        schemeManagement: XCSchemeManagement? = XCSchemeManagement(
            schemeUserState: [
                XCSchemeManagement.UserStateScheme(
                    name: "App.xcscheme",
                    shared: true,
                    orderHint: 0,
                    isShown: true
                ),
            ],
            suppressBuildableAutocreation: nil
        )
    ) -> XCUserData {
        XCUserData(
            userName: userName,
            schemes: schemes,
            breakpoints: nil,
            schemeManagement: schemeManagement
        )
    }
}
