import Path
import Testing
import XcodeGraph
@testable import XcodeProj
@testable import XcodeProjMapper

@Suite
struct XCSchemeMapperTests {
    let mockProvider: MockProjectProvider
    let mapper: XCSchemeMapper
    let graphType: GraphType

    init() throws {
        let mockProvider = MockProjectProvider()
        self.mockProvider = mockProvider
        mapper = XCSchemeMapper()
        graphType = .project(mockProvider.sourceDirectory)
    }

    @Test("Maps shared project schemes correctly")
    func testMapSharedProjectSchemes() throws {
        let xcscheme = XCScheme.test(name: "SharedScheme")
        let scheme = try mapper.map(xcscheme, shared: true, graphType: graphType)
        #expect(scheme.name == "SharedScheme")
        #expect(scheme.shared == true)
    }

    @Test("Maps user (non-shared) project schemes correctly")
    func testMapUserSchemes() throws {
        let xcscheme = XCScheme.test(name: "UserScheme")
        let scheme = try mapper.map(xcscheme, shared: false, graphType: graphType)
        #expect(scheme.name == "UserScheme")
        #expect(scheme.shared == false)
    }

    @Test("Maps a build action within a scheme")
    func testMapBuildAction() throws {
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

        let mappedAction = try mapper.mapBuildAction(action: buildAction, graphType: graphType)
        #expect(mappedAction != nil)
        #expect(mappedAction?.targets.count == 1)
        #expect(mappedAction?.targets[0].name == "App")
        #expect(mappedAction?.runPostActionsOnFailure == true)
        #expect(mappedAction?.findImplicitDependencies == true)
    }

    @Test("Maps a test action with testable references, coverage, and environment")
    func testMapTestAction() throws {
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

        let envVar = XCScheme.EnvironmentVariable(variable: "TEST_ENV", value: "test_value", enabled: true)
        let launchArg = XCScheme.CommandLineArguments.CommandLineArgument(name: "test_arg", enabled: true)

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

        let mappedAction = try mapper.mapTestAction(action: testAction, graphType: graphType)
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
        let targetRef = XCScheme.BuildableReference(
            referencedContainer: "container:App.xcodeproj",
            blueprintIdentifier: "123",
            buildableName: "App.app",
            blueprintName: "App"
        )

        let runnable = XCScheme.BuildableProductRunnable(buildableReference: targetRef)
        let envVar = XCScheme.EnvironmentVariable(variable: "RUN_ENV", value: "run_value", enabled: true)
        let launchArg = XCScheme.CommandLineArguments.CommandLineArgument(name: "run_arg", enabled: true)

        let launchAction = XCScheme.LaunchAction(
            pathRunnable: try XCScheme.PathRunnable(element: runnable.xmlElement()),
            buildConfiguration: "Debug",
            selectedDebuggerIdentifier: "",
            commandlineArguments: XCScheme.CommandLineArguments(arguments: [launchArg]),
            environmentVariables: [envVar]
        )

        let mappedAction = try mapper.mapRunAction(action: launchAction, graphType: graphType)
        #expect(mappedAction != nil)
        #expect(mappedAction?.executable?.name == "App")
        #expect(mappedAction?.configurationName == "Debug")
        #expect(mappedAction?.attachDebugger == true)
        #expect(mappedAction?.arguments?.environmentVariables["RUN_ENV"]?.value == "run_value")
        #expect(mappedAction?.arguments?.launchArguments.first?.name == "run_arg")
    }

    @Test("Maps an archive action with organizer reveal enabled")
    func testMapArchiveAction() throws {
        let archiveAction = XCScheme.ArchiveAction(
            buildConfiguration: "Release",
            revealArchiveInOrganizer: true
        )

        let mappedAction = try mapper.mapArchiveAction(action: archiveAction)
        #expect(mappedAction != nil)
        #expect(mappedAction?.configurationName == "Release")
        #expect(mappedAction?.revealArchiveInOrganizer == true)
    }

    @Test("Maps a profile action to a runnable and configuration")
    func testMapProfileAction() throws {
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

        let mappedAction = try mapper.mapProfileAction(action: profileAction, graphType: graphType)
        #expect(mappedAction != nil)
        #expect(mappedAction?.executable?.name == "App")
        #expect(mappedAction?.configurationName == "Release")
    }

    @Test("Maps an analyze action to the appropriate configuration")
    func testMapAnalyzeAction() throws {
        let analyzeAction = XCScheme.AnalyzeAction(buildConfiguration: "Debug")
        let mappedAction = try mapper.mapAnalyzeAction(action: analyzeAction)
        #expect(mappedAction != nil)
        #expect(mappedAction?.configurationName == "Debug")
    }

    @Test("Maps target references in a scheme's build action")
    func testMapTargetReference() throws {
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
        let mapped = try mapper.map(scheme, shared: true, graphType: graphType)
        let mappedBuildAction = try #require(mapped.buildAction)

        #expect(mappedBuildAction.targets.count == 1)
        #expect(mappedBuildAction.targets[0].name == "App")
        #expect(mappedBuildAction.targets[0].projectPath == mockProvider.sourceDirectory)
    }

    @Test("Handles schemes without any actions gracefully")
    func testNilActions() throws {
        let scheme = XCScheme.test(
            buildAction: nil,
            testAction: nil,
            launchAction: nil,
            archiveAction: nil,
            profileAction: nil,
            analyzeAction: nil
        )

        let mapped = try mapper.map(scheme, shared: true, graphType: graphType)
        #expect(mapped.buildAction == nil)
        #expect(mapped.testAction == nil)
        #expect(mapped.runAction == nil)
        #expect(mapped.profileAction == nil)
        #expect(mapped.analyzeAction == nil)
        #expect(mapped.archiveAction == nil)
    }
}
