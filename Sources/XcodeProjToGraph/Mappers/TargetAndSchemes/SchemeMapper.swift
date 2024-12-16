import Foundation
import Path
import XcodeGraph
import XcodeProj

/// A protocol defining how to map `XCScheme` objects and their associated actions into domain `Scheme` models.
///
/// Conforming types transform raw `XCScheme` instances—along with their build, test, run, archive, profile,
/// and analyze actions—into fully-realized `Scheme` models. This enables further analysis, code generation,
/// or integration with custom tooling based on standardized scheme data.
protocol SchemeMapping: Sendable {
    /// Maps an array of `XCScheme` instances into `Scheme` models.
    ///
    /// - Parameters:
    ///   - xcschemes: An array of `XCScheme` instances to map.
    ///   - shared: A Boolean indicating whether these schemes are shared.
    /// - Returns: An array of mapped `Scheme` instances representing the provided XCSchemes.
    /// - Throws: If any scheme cannot be fully resolved or mapped.
    func mapSchemes(xcschemes: [XCScheme], shared: Bool) async throws -> [Scheme]

    /// Maps a single `XCScheme` into a `Scheme` model.
    ///
    /// - Parameters:
    ///   - xcscheme: The `XCScheme` to map.
    ///   - shared: A Boolean indicating whether the scheme is shared.
    /// - Returns: A `Scheme` model corresponding to the given `XCScheme`.
    /// - Throws: If any of the scheme's actions (build, test, run, etc.) cannot be resolved.
    func mapScheme(xcscheme: XCScheme, shared: Bool) async throws -> Scheme

    /// Maps an `XCScheme.BuildAction` into a `BuildAction` model.
    ///
    /// - Parameter action: The `XCScheme.BuildAction` to map, if any.
    /// - Returns: A `BuildAction` instance, or `nil` if `action` is `nil`.
    /// - Throws: If any target references in the build action cannot be resolved.
    func mapBuildAction(action: XCScheme.BuildAction?) async throws -> BuildAction?

    /// Maps an `XCScheme.LaunchAction` into a `RunAction` model.
    ///
    /// - Parameter action: The `XCScheme.LaunchAction` to map, if any.
    /// - Returns: A `RunAction` instance, or `nil` if `action` is `nil`.
    /// - Throws: If the executable reference cannot be resolved.
    func mapRunAction(action: XCScheme.LaunchAction?) async throws -> RunAction?

    /// Maps an `XCScheme.TestAction` into a `TestAction` model.
    ///
    /// - Parameter action: The `XCScheme.TestAction` to map, if any.
    /// - Returns: A `TestAction` instance, or `nil` if `action` is `nil`.
    /// - Throws: If any test target references cannot be resolved.
    func mapTestAction(action: XCScheme.TestAction?) async throws -> TestAction?

    /// Maps an `XCScheme.ArchiveAction` into an `ArchiveAction` model.
    ///
    /// - Parameter action: The `XCScheme.ArchiveAction` to map, if any.
    /// - Returns: An `ArchiveAction` instance, or `nil` if `action` is `nil`.
    func mapArchiveAction(action: XCScheme.ArchiveAction?) async throws -> ArchiveAction?

    /// Maps an `XCScheme.ProfileAction` into a `ProfileAction` model.
    ///
    /// - Parameter action: The `XCScheme.ProfileAction` to map, if any.
    /// - Returns: A `ProfileAction` instance, or `nil` if `action` is `nil`.
    func mapProfileAction(action: XCScheme.ProfileAction?) async throws -> ProfileAction?

    /// Maps an `XCScheme.AnalyzeAction` into an `AnalyzeAction` model.
    ///
    /// - Parameter action: The `XCScheme.AnalyzeAction` to map, if any.
    /// - Returns: An `AnalyzeAction` instance, or `nil` if `action` is `nil`.
    func mapAnalyzeAction(action: XCScheme.AnalyzeAction?) async throws -> AnalyzeAction?
}

/// Defines the type of scheme mapper based on the source of the graph.
enum SchemeMapperType {
    /// A workspace-based scheme mapper that may have multiple projects.
    case workspace(workspacePath: AbsolutePath, pathProviders: [AbsolutePath: ProjectProviding])
    /// A project-based scheme mapper dealing with a single project.
    case project(provider: ProjectProviding)
}

/// A mapper responsible for converting `XCScheme` objects (and related Xcode scheme configurations)
/// into domain `Scheme` models.
///
/// `SchemeMapper` resolves references to targets, environment variables, launch arguments, and all actions within
/// a scheme (build, test, run, archive, profile, analyze). The resulting `Scheme` models enable consumers
/// to analyze scheme configurations, generate code, or integrate with custom tooling pipelines.
///
/// **Example Usage:**
/// ```swift
/// // Assume you have determined the graphType (e.g., from a workspace or a single project)
/// let graphType: GraphType = ...
///
/// // Create a SchemeMapper
/// let schemeMapper = try SchemeMapper(graphType: graphType)
///
/// // Obtain an array of XCScheme instances (perhaps from XcodeProj's shared or user schemes)
/// let xcschemes: [XCScheme] = ...
///
/// // Map the schemes into Scheme models
/// let schemes = try await schemeMapper.mapSchemes(xcschemes: xcschemes, shared: true)
///
/// // 'schemes' now contains a list of domain Scheme models ready for further use.
/// ```
public final class SchemeMapper: SchemeMapping {
    private let graphType: GraphType

    /// Initializes the mapper with the given graph type.
    ///
    /// - Parameter graphType: The graph type (workspace or project) that influences how target references are resolved.
    /// - Throws: `MappingError.noProjectsFound` if required project information is missing.
    public init(graphType: GraphType) throws {
        self.graphType = graphType
    }

    public func mapSchemes(xcschemes: [XCScheme], shared: Bool) async throws -> [Scheme] {
        try await xcschemes.asyncCompactMap { xcscheme in
            try await self.mapScheme(xcscheme: xcscheme, shared: shared)
        }
    }

    public func mapScheme(xcscheme: XCScheme, shared: Bool) async throws -> Scheme {
        Scheme(
            name: xcscheme.name,
            shared: shared,
            hidden: false,
            buildAction: try await mapBuildAction(action: xcscheme.buildAction),
            testAction: try await mapTestAction(action: xcscheme.testAction),
            runAction: try await mapRunAction(action: xcscheme.launchAction),
            archiveAction: try await mapArchiveAction(action: xcscheme.archiveAction),
            profileAction: try await mapProfileAction(action: xcscheme.profileAction),
            analyzeAction: try await mapAnalyzeAction(action: xcscheme.analyzeAction)
        )
    }

    public func mapBuildAction(action: XCScheme.BuildAction?) async throws -> BuildAction? {
        guard let action else { return nil }

        let targets = try await action.buildActionEntries.asyncCompactMap { entry in
            let buildableReference = entry.buildableReference
            return try await self.mapTargetReference(buildableReference: buildableReference)
        }

        return BuildAction(
            targets: targets,
            preActions: [],
            postActions: [],
            runPostActionsOnFailure: action.runPostActionsOnFailure ?? false,
            findImplicitDependencies: action.buildImplicitDependencies
        )
    }

    public func mapTestAction(action: XCScheme.TestAction?) async throws -> TestAction? {
        guard let action else { return nil }

        let testTargets = try await action.testables.asyncCompactMap { testable in
            let targetReference = try await self.mapTargetReference(
                buildableReference: testable.buildableReference
            )
            return TestableTarget(target: targetReference, skipped: testable.skipped)
        }

        let environmentVariables =
            action.environmentVariables?.reduce(into: [String: EnvironmentVariable]()) { dict, variable in
                dict[variable.variable] = EnvironmentVariable(
                    value: variable.value, isEnabled: variable.enabled
                )
            } ?? [:]

        let launchArguments =
            action.commandlineArguments?.arguments.map {
                LaunchArgument(name: $0.name, isEnabled: $0.enabled)
            } ?? []

        let arguments = Arguments(
            environmentVariables: environmentVariables,
            launchArguments: launchArguments
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

    public func mapRunAction(action: XCScheme.LaunchAction?) async throws -> RunAction? {
        guard let action else { return nil }

        let executable: TargetReference? = try await {
            if let buildableRef = action.runnable?.buildableReference {
                return try await mapTargetReference(buildableReference: buildableRef)
            } else {
                return nil
            }
        }()

        let environmentVariables =
            action.environmentVariables?.reduce(into: [String: EnvironmentVariable]()) { dict, variable in
                dict[variable.variable] = EnvironmentVariable(
                    value: variable.value, isEnabled: variable.enabled
                )
            } ?? [:]

        let launchArguments =
            action.commandlineArguments?.arguments.map {
                LaunchArgument(name: $0.name, isEnabled: $0.enabled)
            } ?? []

        let arguments = Arguments(
            environmentVariables: environmentVariables,
            launchArguments: launchArguments
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

    public func mapArchiveAction(action: XCScheme.ArchiveAction?) async throws -> ArchiveAction? {
        guard let action else { return nil }

        return ArchiveAction(
            configurationName: action.buildConfiguration,
            revealArchiveInOrganizer: action.revealArchiveInOrganizer
        )
    }

    public func mapProfileAction(action: XCScheme.ProfileAction?) async throws -> ProfileAction? {
        guard let action else { return nil }

        let executable: TargetReference? = try await {
            if let buildableRef = action.buildableProductRunnable?.buildableReference {
                return try await mapTargetReference(buildableReference: buildableRef)
            } else {
                return nil
            }
        }()

        return ProfileAction(
            configurationName: action.buildConfiguration,
            executable: executable
        )
    }

    public func mapAnalyzeAction(action: XCScheme.AnalyzeAction?) async throws -> AnalyzeAction? {
        guard let action else { return nil }
        return AnalyzeAction(configurationName: action.buildConfiguration)
    }

    /// Maps a `XCScheme.BuildableReference` to a `TargetReference`.
    ///
    /// This step involves resolving the container path and the target name, which differ depending on whether
    /// the scheme originates from a workspace or a standalone project.
    ///
    /// - Parameter buildableReference: The `XCScheme.BuildableReference` to map.
    /// - Returns: A `TargetReference` representing the target in the resolved container.
    /// - Throws: If the referenced container cannot be resolved.
    private func mapTargetReference(buildableReference: XCScheme.BuildableReference) async throws
        -> TargetReference
    {
        let targetName = buildableReference.blueprintName
        let container = buildableReference.referencedContainer

        let projectPath: AbsolutePath
        switch graphType {
        case let .workspace(workspaceProvider):
            let containerRelativePath = container.replacingOccurrences(of: "container:", with: "")
            let relativePath = try RelativePath(validating: containerRelativePath)
            projectPath = workspaceProvider.workspaceDirectory.appending(relativePath)
        case let .project(path):
            projectPath = path
        }

        return TargetReference(
            projectPath: projectPath,
            name: targetName
        )
    }
}

extension SchemeMapper {
    /// Maps the given Xcode schemes asynchronously.
    ///
    /// This is a convenience method similar to `mapSchemes(xcschemes:shared:)`,
    /// but specifically defined for asynchronous mapping flows.
    ///
    /// - Parameters:
    ///   - xcschemes: An array of `XCScheme` instances to map.
    ///   - shared: A Boolean indicating whether the schemes are shared.
    /// - Returns: An array of mapped `Scheme` instances.
    /// - Throws: If mapping any scheme fails.
    func mapSchemesAsync(xcschemes: [XCScheme], shared: Bool) async throws -> [Scheme] {
        try await xcschemes.asyncCompactMap { scheme in
            try await self.mapScheme(xcscheme: scheme, shared: shared)
        }
    }
}
