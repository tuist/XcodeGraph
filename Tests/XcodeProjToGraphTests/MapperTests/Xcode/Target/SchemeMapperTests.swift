import Path
import Testing
@testable import TestSupport
@testable import XcodeProj
@testable import XcodeProjToGraph

struct SchemeMapperTests {
    let mockProvider: MockProjectProvider
    let mapper: SchemeMapper

    init() async throws {
        let mockProvider = MockProjectProvider()
        self.mockProvider = mockProvider
        mapper = try SchemeMapper(graphType: .project(mockProvider.sourceDirectory))
    }

    @Test func testMapSharedProjectSchemes() async throws {
        // Setup shared scheme data
        let xcscheme = XCScheme.mock(name: "SharedScheme")

        let schemes = try await mapper.mapSchemes(xcschemes: [xcscheme], shared: true)
        #expect(schemes.count == 1)
        #expect(schemes[0].name == "SharedScheme")
        #expect(schemes[0].shared == true)
    }

    @Test func testMapUserSchemes() async throws {
        // Setup user scheme data
        let xcscheme = XCScheme.mock(name: "UserScheme")
        let schemes = try await mapper.mapSchemes(xcschemes: [xcscheme], shared: false)

        #expect(schemes.count == 1)
        #expect(schemes[0].name == "UserScheme")
        #expect(schemes[0].shared == false)
    }

    @Test func testMapBuildAction() async throws {
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

    @Test func testMapTestAction() async throws {
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

    @Test func testMapRunAction() async throws {
        let targetRef = XCScheme.BuildableReference(
            referencedContainer: "container:App.xcodeproj",
            blueprintIdentifier: "123",
            buildableName: "App.app",
            blueprintName: "App"
        )

        let runnable = XCScheme.BuildableProductRunnable(buildableReference: targetRef)

        let envVar = XCScheme.EnvironmentVariable(
            variable: "RUN_ENV",
            value: "run_value",
            enabled: true
        )

        let launchArg = XCScheme.CommandLineArguments.CommandLineArgument(
            name: "run_arg",
            enabled: true
        )

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

    @Test func testMapArchiveAction() async throws {
        let archiveAction = XCScheme.ArchiveAction(
            buildConfiguration: "Release",
            revealArchiveInOrganizer: true
        )

        let mappedAction = try await mapper.mapArchiveAction(action: archiveAction)
        #expect(mappedAction != nil)
        #expect(mappedAction?.configurationName == "Release")
        #expect(mappedAction?.revealArchiveInOrganizer == true)
    }

    @Test func testMapProfileAction() async throws {
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

    @Test func testMapAnalyzeAction() async throws {
        let analyzeAction = XCScheme.AnalyzeAction(buildConfiguration: "Debug")

        let mappedAction = try await mapper.mapAnalyzeAction(action: analyzeAction)
        #expect(mappedAction != nil)
        #expect(mappedAction?.configurationName == "Debug")
    }

    @Test func testMapTargetReference() async throws {
        let targetRef = XCScheme.BuildableReference(
            referencedContainer: "container:App.xcodeproj",
            blueprintIdentifier: "123",
            buildableName: "App.app",
            blueprintName: "App"
        )

        // Create a build action entry that uses the target reference
        let buildActionEntry = XCScheme.BuildAction.Entry(
            buildableReference: targetRef,
            buildFor: [.running]
        )

        // Create a scheme with a build action that uses our target reference
        let buildAction = XCScheme.BuildAction(
            buildActionEntries: [buildActionEntry],
            parallelizeBuild: true,
            buildImplicitDependencies: true
        )

        let scheme = XCScheme.mock(buildAction: buildAction)

        let mapped = try await mapper.mapScheme(xcscheme: scheme, shared: true)

        // Verify the target reference was properly mapped
        let mappedBuildAction = try #require(mapped.buildAction)

        #expect(mappedBuildAction.targets.count == 1)
        #expect(mappedBuildAction.targets[0].name == "App")
        #expect(mappedBuildAction.targets[0].projectPath == mockProvider.sourceDirectory)
    }

    @Test func testNilActions() async throws {
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
