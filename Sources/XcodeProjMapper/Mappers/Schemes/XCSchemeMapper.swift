import Foundation
import Path
import XcodeGraph
import XcodeProj

/// A protocol defining how to map a single `XCScheme` object (and its actions) into a domain `Scheme` model.
///
/// Conforming types translate a raw `XCScheme` instance, including its build, test, run, archive, profile,
/// and analyze actions, into a `Scheme` model ready for analysis, code generation, or tooling integration.
protocol SchemeMapping {
    /// Maps a single `XCScheme` into a `Scheme` model.
    ///
    /// - Parameters:
    ///   - xcscheme: The `XCScheme` to map.
    ///   - shared: Indicates whether the scheme is shared.
    /// - Returns: A `Scheme` model corresponding to the given `XCScheme`.
    /// - Throws: If any of the scheme's actions (build, test, run, etc.) cannot be resolved.
    func map(
        _ xcscheme: XCScheme,
        shared: Bool,
        graphType: XcodeMapperGraphType
    ) throws -> Scheme
}

/// A mapper responsible for converting an `XCScheme` object into a `Scheme` model.
///
/// `SchemeMapper` resolves references to targets, variables, and all scheme actions.
/// The resulting `Scheme` models enable analysis, code generation, or integration with tooling.
struct XCSchemeMapper: SchemeMapping {
    func map(
        _ xcscheme: XCScheme,
        shared: Bool,
        graphType: XcodeMapperGraphType
    ) throws -> Scheme {
        Scheme(
            name: xcscheme.name,
            shared: shared,
            hidden: false,
            buildAction: try mapBuildAction(action: xcscheme.buildAction, graphType: graphType),
            testAction: try mapTestAction(action: xcscheme.testAction, graphType: graphType),
            runAction: try mapRunAction(action: xcscheme.launchAction, graphType: graphType),
            archiveAction: try mapArchiveAction(action: xcscheme.archiveAction),
            profileAction: try mapProfileAction(action: xcscheme.profileAction, graphType: graphType),
            analyzeAction: try mapAnalyzeAction(action: xcscheme.analyzeAction)
        )
    }

    // MARK: - Internal/Private Mappings

    func mapBuildAction(action: XCScheme.BuildAction?, graphType: XcodeMapperGraphType) throws -> BuildAction? {
        guard let action else { return nil }

        let targets = try action.buildActionEntries.compactMap { entry in
            try mapTargetReference(buildableReference: entry.buildableReference, graphType: graphType)
        }

        return BuildAction(
            targets: targets,
            preActions: [],
            postActions: [],
            runPostActionsOnFailure: action.runPostActionsOnFailure ?? false,
            findImplicitDependencies: action.buildImplicitDependencies
        )
    }

    func mapTestAction(action: XCScheme.TestAction?, graphType: XcodeMapperGraphType) throws -> TestAction? {
        guard let action else { return nil }

        let testTargets = try action.testables.compactMap { testable in
            let targetReference = try mapTargetReference(
                buildableReference: testable.buildableReference,
                graphType: graphType
            )
            return TestableTarget(target: targetReference, skipped: testable.skipped)
        }

        let arguments = mapArguments(
            environmentVariables: action.environmentVariables,
            commandlineArguments: action.commandlineArguments
        )
        let diagnosticsOptions = SchemeDiagnosticsOptions(action: action)

        return TestAction(
            targets: testTargets,
            arguments: arguments,
            configurationName: action.buildConfiguration,
            attachDebugger: true,
            coverage: action.codeCoverageEnabled,
            codeCoverageTargets: [],
            expandVariableFromTarget: nil,
            preActions: [],
            postActions: [],
            diagnosticsOptions: diagnosticsOptions,
            language: action.language,
            region: action.region
        )
    }

    func mapRunAction(action: XCScheme.LaunchAction?, graphType: XcodeMapperGraphType) throws -> RunAction? {
        guard let action else { return nil }

        let executable: TargetReference? = try {
            if let buildableRef = action.runnable?.buildableReference {
                return try mapTargetReference(buildableReference: buildableRef, graphType: graphType)
            }
            return nil
        }()

        let arguments = mapArguments(
            environmentVariables: action.environmentVariables,
            commandlineArguments: action.commandlineArguments
        )
        let diagnosticsOptions = SchemeDiagnosticsOptions(action: action)
        let attachDebugger = action.selectedDebuggerIdentifier.isEmpty

        return RunAction(
            configurationName: action.buildConfiguration,
            attachDebugger: attachDebugger,
            customLLDBInitFile: nil,
            preActions: [],
            postActions: [],
            executable: executable,
            filePath: nil,
            arguments: arguments,
            options: RunActionOptions(),
            diagnosticsOptions: diagnosticsOptions
        )
    }

    func mapArchiveAction(action: XCScheme.ArchiveAction?) throws -> ArchiveAction? {
        guard let action else { return nil }
        return ArchiveAction(
            configurationName: action.buildConfiguration,
            revealArchiveInOrganizer: action.revealArchiveInOrganizer
        )
    }

    func mapProfileAction(action: XCScheme.ProfileAction?, graphType: XcodeMapperGraphType) throws -> ProfileAction? {
        guard let action else { return nil }

        let executable: TargetReference? = try {
            if let buildableRef = action.buildableProductRunnable?.buildableReference {
                return try mapTargetReference(buildableReference: buildableRef, graphType: graphType)
            }
            return nil
        }()

        return ProfileAction(
            configurationName: action.buildConfiguration,
            executable: executable
        )
    }

    func mapAnalyzeAction(action: XCScheme.AnalyzeAction?) throws -> AnalyzeAction? {
        guard let action else { return nil }
        return AnalyzeAction(configurationName: action.buildConfiguration)
    }

    // MARK: - Private Helpers

    private func mapTargetReference(
        buildableReference: XCScheme.BuildableReference,
        graphType: XcodeMapperGraphType
    ) throws -> TargetReference {
        let targetName = buildableReference.blueprintName
        let container = buildableReference.referencedContainer

        let projectPath: AbsolutePath
        switch graphType {
        case let .workspace(xcworkspace):
            let containerRelativePath = container.replacingOccurrences(of: "container:", with: "")
            let relativePath = try RelativePath(validating: containerRelativePath)
            projectPath = try xcworkspace.pathOrThrow.parentDirectory.appending(relativePath)
        case let .project(xcodeProj):
            projectPath = try xcodeProj.pathOrThrow
        }

        return TargetReference(projectPath: projectPath, name: targetName)
    }

    private func mapArguments(
        environmentVariables: [XCScheme.EnvironmentVariable]?,
        commandlineArguments: XCScheme.CommandLineArguments?
    ) -> Arguments {
        let envVariables = environmentVariables?.reduce(into: [String: EnvironmentVariable]()) { dict, variable in
            dict[variable.variable] = EnvironmentVariable(value: variable.value, isEnabled: variable.enabled)
        } ?? [:]

        let launchArguments = commandlineArguments?.arguments.map {
            LaunchArgument(name: $0.name, isEnabled: $0.enabled)
        } ?? []

        return Arguments(environmentVariables: envVariables, launchArguments: launchArguments)
    }
}
