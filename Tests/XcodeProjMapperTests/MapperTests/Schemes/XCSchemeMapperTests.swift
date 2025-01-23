import AEXML
import Path
import Testing
import XcodeGraph
@testable import XcodeProj
@testable import XcodeProjMapper

@Suite
struct XCSchemeMapperTests {
    let xcodeProj: XcodeProj
    let mapper: XCSchemeMapper
    let graphType: XcodeMapperGraphType

    init() throws {
        xcodeProj = XcodeProj.test()
        mapper = XCSchemeMapper()
        graphType = .project(xcodeProj)
    }

    @Test("Maps shared project schemes correctly")
    func testMapSharedProjectSchemes() throws {
        // Given
        let xcscheme = XCScheme.test(name: "SharedScheme")

        // When
        let scheme = try mapper.map(xcscheme, shared: true, graphType: graphType)

        // Then
        #expect(scheme.name == "SharedScheme")
        #expect(scheme.shared == true)
    }

    @Test("Maps user (non-shared) project schemes correctly")
    func testMapUserSchemes() throws {
        // Given
        let xcscheme = XCScheme.test(name: "UserScheme")

        // When
        let scheme = try mapper.map(xcscheme, shared: false, graphType: graphType)

        // Then
        #expect(scheme.name == "UserScheme")
        #expect(scheme.shared == false)
    }

    @Test("Maps a build action within a scheme")
    func testMapBuildAction() throws {
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

        // When
        let mappedAction = try mapper.mapBuildAction(action: buildAction, graphType: graphType)

        // Then
        #expect(mappedAction != nil)
        #expect(mappedAction?.targets.count == 1)
        #expect(mappedAction?.targets[0].name == "App")
        #expect(mappedAction?.runPostActionsOnFailure == true)
        #expect(mappedAction?.findImplicitDependencies == true)
    }

    @Test("Maps a test action with testable references, coverage, and environment")
    func testMapTestAction() throws {
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

        // When
        let mappedAction = try mapper.mapTestAction(action: testAction, graphType: graphType)

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
    func testMapRunAction() throws {
        // Given
        let targetRef = XCScheme.BuildableReference(
            referencedContainer: "container:App.xcodeproj",
            blueprintIdentifier: "123",
            buildableName: "App.app",
            blueprintName: "App"
        )
        let runnable = XCScheme.BuildableProductRunnable(buildableReference: targetRef)
        let envVar = XCScheme.EnvironmentVariable(variable: "RUN_ENV", value: "run_value", enabled: true)
        let launchArg = XCScheme.CommandLineArguments.CommandLineArgument(name: "run_arg", enabled: true)
        let element = runnable.xmlElement()
        let launchAction = XCScheme.LaunchAction(
            runnable: try .init(element: element),
            buildConfiguration: "Debug",
            selectedDebuggerIdentifier: "",
            commandlineArguments: XCScheme.CommandLineArguments(arguments: [launchArg]),
            environmentVariables: [envVar]
        )

        // When
        let mappedAction = try mapper.mapRunAction(action: launchAction, graphType: graphType)

        // Then
        #expect(mappedAction != nil)
        #expect(mappedAction?.executable?.name == "App")
        #expect(mappedAction?.configurationName == "Debug")
        #expect(mappedAction?.attachDebugger == true)
        #expect(mappedAction?.arguments?.environmentVariables["RUN_ENV"]?.value == "run_value")
        #expect(mappedAction?.arguments?.launchArguments.first?.name == "run_arg")
    }

    @Test("Maps an archive action with organizer reveal enabled")
    func testMapArchiveAction() throws {
        // Given
        let archiveAction = XCScheme.ArchiveAction(
            buildConfiguration: "Release",
            revealArchiveInOrganizer: true
        )

        // When
        let mappedAction = try mapper.mapArchiveAction(action: archiveAction)

        // Then
        #expect(mappedAction != nil)
        #expect(mappedAction?.configurationName == "Release")
        #expect(mappedAction?.revealArchiveInOrganizer == true)
    }

    @Test("Maps a profile action to a runnable and configuration")
    func testMapProfileAction() throws {
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

        // When
        let mappedAction = try mapper.mapProfileAction(action: profileAction, graphType: graphType)

        // Then
        #expect(mappedAction != nil)
        #expect(mappedAction?.executable?.name == "App")
        #expect(mappedAction?.configurationName == "Release")
    }

    @Test("Maps an analyze action to the appropriate configuration")
    func testMapAnalyzeAction() throws {
        // Given
        let analyzeAction = XCScheme.AnalyzeAction(buildConfiguration: "Debug")

        // When
        let mappedAction = try mapper.mapAnalyzeAction(action: analyzeAction)

        // Then
        #expect(mappedAction != nil)
        #expect(mappedAction?.configurationName == "Debug")
    }

    @Test("Maps target references in a scheme's build action")
    func testMapTargetReference() throws {
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
        let scheme = XCScheme.test(buildAction: buildAction)

        // When
        let mapped = try mapper.map(scheme, shared: true, graphType: graphType)
        let mappedBuildAction = try #require(mapped.buildAction)

        // Then
        #expect(mappedBuildAction.targets.count == 1)
        #expect(mappedBuildAction.targets[0].name == "App")
        #expect(mappedBuildAction.targets[0].projectPath == xcodeProj.projectPath)
    }

    @Test("Handles schemes without any actions gracefully")
    func testNilActions() throws {
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
