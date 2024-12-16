import Path
import Testing
@testable import TestSupport
@testable import XcodeProj
@testable import XcodeProjToGraph

@Suite
struct SchemeMapperTests {
    let mockProvider: MockProjectProvider
    let mapper: SchemeMapper

    init() async throws {
        let mockProvider = MockProjectProvider()
        self.mockProvider = mockProvider
        mapper = try SchemeMapper(graphType: .project(mockProvider.sourceDirectory))
    }

    @Test("Maps shared project schemes correctly")
    func testMapSharedProjectSchemes() async throws {
        // Setup a shared scheme
        let xcscheme = XCScheme.mock(name: "SharedScheme")

        let schemes = try await mapper.mapSchemes(xcschemes: [xcscheme], shared: true)
        #expect(schemes.count == 1)
        #expect(schemes[0].name == "SharedScheme")
        #expect(schemes[0].shared == true)
    }

    @Test("Maps user (non-shared) project schemes correctly")
    func testMapUserSchemes() async throws {
        // Setup a user scheme
        let xcscheme = XCScheme.mock(name: "UserScheme")
        let schemes = try await mapper.mapSchemes(xcschemes: [xcscheme], shared: false)

        #expect(schemes.count == 1)
        #expect(schemes[0].name == "UserScheme")
        #expect(schemes[0].shared == false)
    }

    @Test("Maps a build action within a scheme")
    func testMapBuildAction() async throws {
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

        let mappedAction = try await mapper.mapBuildAction(action: buildAction)
        #expect(mappedAction != nil)
        #expect(mappedAction?.targets.count == 1)
        #expect(mappedAction?.targets[0].name == "App")
        #expect(mappedAction?.runPostActionsOnFailure == true)
        #expect(mappedAction?.findImplicitDependencies == true)
    }

    @Test("Maps a test action with testable references, coverage, and environment")
    func testMapTestAction() async throws {
        let targetRef = XCScheme.BuildableReference(
            referencedContainer: "container:App.xcodeproj",
            blueprintIdentifier: "123",
            buildableName: "AppTests.xctest",
            blueprintName: "AppTests"
        )

        let testableEntry = XCScheme.TestableReference.mock(
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

        let mappedAction = try await mapper.mapTestAction(action: testAction)
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

        let mappedAction = try await mapper.mapRunAction(action: launchAction)
        #expect(mappedAction != nil)
        #expect(mappedAction?.executable?.name == "App")
        #expect(mappedAction?.configurationName == "Debug")
        #expect(mappedAction?.attachDebugger == true)
        #expect(mappedAction?.arguments?.environmentVariables["RUN_ENV"]?.value == "run_value")
        #expect(mappedAction?.arguments?.launchArguments.first?.name == "run_arg")
    }

    @Test("Maps an archive action with organizer reveal enabled")
    func testMapArchiveAction() async throws {
        let archiveAction = XCScheme.ArchiveAction(
            buildConfiguration: "Release",
            revealArchiveInOrganizer: true
        )

        let mappedAction = try await mapper.mapArchiveAction(action: archiveAction)
        #expect(mappedAction != nil)
        #expect(mappedAction?.configurationName == "Release")
        #expect(mappedAction?.revealArchiveInOrganizer == true)
    }

    @Test("Maps a profile action to a runnable and configuration")
    func testMapProfileAction() async throws {
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

        let mappedAction = try await mapper.mapProfileAction(action: profileAction)
        #expect(mappedAction != nil)
        #expect(mappedAction?.executable?.name == "App")
        #expect(mappedAction?.configurationName == "Release")
    }

    @Test("Maps an analyze action to the appropriate configuration")
    func testMapAnalyzeAction() async throws {
        let analyzeAction = XCScheme.AnalyzeAction(buildConfiguration: "Debug")

        let mappedAction = try await mapper.mapAnalyzeAction(action: analyzeAction)
        #expect(mappedAction != nil)
        #expect(mappedAction?.configurationName == "Debug")
    }

    @Test("Maps target references in a scheme's build action")
    func testMapTargetReference() async throws {
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

        let scheme = XCScheme.mock(buildAction: buildAction)

        let mapped = try await mapper.mapScheme(xcscheme: scheme, shared: true)

        let mappedBuildAction = try #require(mapped.buildAction)
        #expect(mappedBuildAction.targets.count == 1)
        #expect(mappedBuildAction.targets[0].name == "App")
        #expect(mappedBuildAction.targets[0].projectPath == mockProvider.sourceDirectory)
    }

    @Test("Handles schemes without any actions gracefully")
    func testNilActions() async throws {
        let scheme = XCScheme.mock(
            buildAction: nil,
            testAction: nil,
            launchAction: nil,
            archiveAction: nil,
            profileAction: nil,
            analyzeAction: nil
        )

        let mapped = try await mapper.mapScheme(xcscheme: scheme, shared: true)
        #expect(mapped.buildAction == nil)
        #expect(mapped.testAction == nil)
        #expect(mapped.runAction == nil)
        #expect(mapped.profileAction == nil)
        #expect(mapped.analyzeAction == nil)
        #expect(mapped.archiveAction == nil)
    }
}
