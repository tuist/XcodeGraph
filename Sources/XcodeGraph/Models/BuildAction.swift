import Foundation
import Path

public struct BuildAction: Equatable, Codable, Sendable {
    // MARK: - Attributes

    public var targets: [TargetReference]
    public var preActions: [ExecutionAction]
    public var postActions: [ExecutionAction]
    public var parallelizeBuild: Bool
    public var runPostActionsOnFailure: Bool
    public var findImplicitDependencies: Bool
    public var overrideArchitectures: Architectures

    // MARK: - Init

    public init(
        targets: [TargetReference] = [],
        preActions: [ExecutionAction] = [],
        postActions: [ExecutionAction] = [],
        parallelizeBuild: Bool = true,
        runPostActionsOnFailure: Bool = false,
        findImplicitDependencies: Bool = true,
        overrideArchitectures: Architectures = .useTargetSettings
    ) {
        self.targets = targets
        self.preActions = preActions
        self.postActions = postActions
        self.parallelizeBuild = parallelizeBuild
        self.runPostActionsOnFailure = runPostActionsOnFailure
        self.findImplicitDependencies = findImplicitDependencies
        self.overrideArchitectures = overrideArchitectures
    }
}

#if DEBUG
    extension BuildAction {
        public static func test(
            // swiftlint:disable:next force_try
            targets: [TargetReference] = [TargetReference(projectPath: try! AbsolutePath(validating: "/Project"), name: "App")],
            preActions: [ExecutionAction] = [],
            postActions: [ExecutionAction] = []
        ) -> BuildAction {
            BuildAction(targets: targets, preActions: preActions, postActions: postActions)
        }
    }
#endif
