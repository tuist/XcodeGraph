import AEXML
import Path
import Testing
import XcodeGraph

@testable import XcodeGraphMapper
@testable import XcodeProj

@Suite
struct XCSchemeMapperTests {
    let xcodeProj: XcodeProj
    let mapper: XCSchemeMapper
    let graphType: XcodeMapperGraphType

    init() async throws {
        xcodeProj = try await XcodeProj.test()
        mapper = XCSchemeMapper()
        graphType = .project(xcodeProj)
    }

    @Test("Maps shared project schemes correctly")
    func testMapSharedProjectSchemes() async throws {
        // Given
        let xcscheme = XCScheme.test(name: "SharedScheme")

        // When
        let scheme = try mapper.map(xcscheme, shared: true, graphType: graphType)

        // Then
        #expect(scheme.name == "SharedScheme")
        #expect(scheme.shared == true)
    }

    @Test("Maps user (non-shared) project schemes correctly")
    func testMapUserSchemes() async throws {
        // Given
        let xcscheme = XCScheme.test(name: "UserScheme")

        // When
        let scheme = try mapper.map(xcscheme, shared: false, graphType: graphType)

        // Then
        #expect(scheme.name == "UserScheme")
        #expect(scheme.shared == false)
    }

    @Test("Maps a build action within a scheme")
    func testMapBuildAction() async throws {
        // Given
        let targetRef = XCScheme.BuildableReference(
            referencedContainer: "container:App.xcodeproj",
            blueprintIdentifier: "123",
            buildableName: "App.app",
            blueprintName: "App"
        )
        let buildActionEntry = XCScheme.BuildAction.Entry(
            buildableReference: targetRef,
            buildFor: [.running, .testing]
        )
        let buildAction = XCScheme.BuildAction(
            buildActionEntries: [buildActionEntry],
            parallelizeBuild: true,
            buildImplicitDependencies: true,
            runPostActionsOnFailure: true
        )
        let xcscheme = XCScheme.test(name: "UserScheme", buildAction: buildAction)

        // When
        let mapped = try mapper.map(xcscheme, shared: false, graphType: graphType)
        let mappedAction = mapped.buildAction
        // Then
        #expect(mappedAction != nil)
        #expect(mappedAction?.targets.count == 1)
        #expect(mappedAction?.targets[0].name == "App")
        #expect(mappedAction?.runPostActionsOnFailure == true)
        #expect(mappedAction?.findImplicitDependencies == true)
    }

    @Test("Maps a test action with testable references, coverage, and environment")
    func testMapTestAction() async throws {
        // Given
        let targetRef = XCScheme.BuildableReference(
            referencedContainer: "container:App.xcodeproj",
            blueprintIdentifier: "123",
            buildableName: "AppTests.xctest",
            blueprintName: "AppTests"
        )
        let testableEntry = XCScheme.TestableReference.test(
            skipped: false,
            buildableReference: targetRef
        )
        let envVar = XCScheme.EnvironmentVariable(
            variable: "TEST_ENV",
            value: "test_value",
            enabled: true
        )
        let launchArg = XCScheme.CommandLineArguments.CommandLineArgument(
            name: "test_arg",
            enabled: true
        )
        let testAction = XCScheme.TestAction(
            buildConfiguration: "Debug",
            macroExpansion: nil,
            testables: [testableEntry],
            codeCoverageEnabled: true,
            commandlineArguments: XCScheme.CommandLineArguments(arguments: [launchArg]),
            environmentVariables: [envVar],
            language: "en",
            region: "US"
        )
        let xcscheme = XCScheme.test(name: "UserScheme", testAction: testAction)

        // When
        let mapped = try mapper.map(xcscheme, shared: false, graphType: graphType)
        let mappedAction = mapped.testAction

        // Then
        #expect(mappedAction != nil)
        #expect(mappedAction?.targets.count == 1)
        #expect(mappedAction?.targets[0].target.name == "AppTests")
        #expect(mappedAction?.configurationName == "Debug")
        #expect(mappedAction?.coverage == true)
        #expect(mappedAction?.arguments?.environmentVariables["TEST_ENV"]?.value == "test_value")
        #expect(mappedAction?.arguments?.launchArguments.first?.name == "test_arg")
        #expect(mappedAction?.language == "en")
        #expect(mappedAction?.region == "US")
    }

    @Test("Maps a run action with environment variables and launch arguments")
    func testMapRunAction() async throws {
        // Given
        let targetRef = XCScheme.BuildableReference(
            referencedContainer: "container:App.xcodeproj",
            blueprintIdentifier: "123",
            buildableName: "App.app",
            blueprintName: "App"
        )
        let runnable = XCScheme.BuildableProductRunnable(buildableReference: targetRef)
        let envVar = XCScheme.EnvironmentVariable(
            variable: "RUN_ENV", value: "run_value", enabled: true
        )
        let launchArg = XCScheme.CommandLineArguments.CommandLineArgument(
            name: "run_arg", enabled: true
        )
        let element = runnable.xmlElement()
        let launchAction = XCScheme.LaunchAction(
            runnable: try .init(element: element),
            buildConfiguration: "Debug",
            selectedDebuggerIdentifier: "",
            commandlineArguments: XCScheme.CommandLineArguments(arguments: [launchArg]),
            environmentVariables: [envVar]
        )

        let xcscheme = XCScheme.test(name: "UserScheme", launchAction: launchAction)

        // When
        let mapped = try mapper.map(xcscheme, shared: false, graphType: graphType)
        let mappedAction = mapped.runAction

        // Then
        #expect(mappedAction != nil)
        #expect(mappedAction?.executable?.name == "App")
        #expect(mappedAction?.configurationName == "Debug")
        #expect(mappedAction?.attachDebugger == true)
        #expect(mappedAction?.arguments?.environmentVariables["RUN_ENV"]?.value == "run_value")
        #expect(mappedAction?.arguments?.launchArguments.first?.name == "run_arg")
    }

    @Test("Maps an archive action with organizer reveal enabled")
    func testMapArchiveAction() async throws {
        // Given
        let archiveAction = XCScheme.ArchiveAction(
            buildConfiguration: "Release",
            revealArchiveInOrganizer: true
        )

        let xcscheme = XCScheme.test(name: "UserScheme", archiveAction: archiveAction)

        // When
        let mapped = try mapper.map(xcscheme, shared: false, graphType: graphType)
        let mappedAction = mapped.archiveAction

        // Then
        #expect(mappedAction != nil)
        #expect(mappedAction?.configurationName == "Release")
        #expect(mappedAction?.revealArchiveInOrganizer == true)
    }

    @Test("Maps a profile action to a runnable and configuration")
    func testMapProfileAction() async throws {
        // Given
        let targetRef = XCScheme.BuildableReference(
            referencedContainer: "container:App.xcodeproj",
            blueprintIdentifier: "123",
            buildableName: "App.app",
            blueprintName: "App"
        )
        let runnable = XCScheme.BuildableProductRunnable(buildableReference: targetRef)
        let profileAction = XCScheme.ProfileAction(
            runnable: runnable,
            buildConfiguration: "Release"
        )

        let xcscheme = XCScheme.test(name: "UserScheme", profileAction: profileAction)

        // When
        let mapped = try mapper.map(xcscheme, shared: false, graphType: graphType)
        let mappedAction = mapped.profileAction

        // Then
        #expect(mappedAction != nil)
        #expect(mappedAction?.executable?.name == "App")
        #expect(mappedAction?.configurationName == "Release")
    }

    @Test("Maps an analyze action to the appropriate configuration")
    func testMapAnalyzeAction() async throws {
        // Given
        let analyzeAction = XCScheme.AnalyzeAction(buildConfiguration: "Debug")

        let xcscheme = XCScheme.test(name: "UserScheme", analyzeAction: analyzeAction)

        // When
        let mapped = try mapper.map(xcscheme, shared: false, graphType: graphType)
        let mappedAction = mapped.analyzeAction

        // Then
        #expect(mappedAction != nil)
        #expect(mappedAction?.configurationName == "Debug")
    }

    @Test("Maps target references in a scheme's build action")
    func testMapTargetReference() async throws {
        // Given
        let targetRef = XCScheme.BuildableReference(
            referencedContainer: "container:App.xcodeproj",
            blueprintIdentifier: "123",
            buildableName: "App.app",
            blueprintName: "App"
        )
        let buildActionEntry = XCScheme.BuildAction.Entry(
            buildableReference: targetRef,
            buildFor: [.running]
        )
        let buildAction = XCScheme.BuildAction(
            buildActionEntries: [buildActionEntry],
            parallelizeBuild: true,
            buildImplicitDependencies: true
        )
        let xcscheme = XCScheme.test(name: "UserScheme", buildAction: buildAction)

        // When
        let mapped = try mapper.map(xcscheme, shared: false, graphType: graphType)
        let mappedAction = try #require(mapped.buildAction)

        // Then
        #expect(mappedAction.targets.count == 1)
        #expect(mappedAction.targets[0].name == "App")
        #expect(mappedAction.targets[0].projectPath == xcodeProj.projectPath)
    }

    @Test("Handles schemes without any actions gracefully")
    func testNilActions() async throws {
        // Given
        let scheme = XCScheme.test(
            buildAction: nil,
            testAction: nil,
            launchAction: nil,
            archiveAction: nil,
            profileAction: nil,
            analyzeAction: nil
        )

        // When
        let mapped = try mapper.map(scheme, shared: true, graphType: graphType)

        // Then
        #expect(mapped.buildAction == nil)
        #expect(mapped.testAction == nil)
        #expect(mapped.runAction == nil)
        #expect(mapped.profileAction == nil)
        #expect(mapped.analyzeAction == nil)
        #expect(mapped.archiveAction == nil)
    }
}
