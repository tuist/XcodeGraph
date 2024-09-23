import Foundation
import Path

public struct BuildAction: Equatable, Codable, Sendable {
    /// It represents the reference to a target from a build action, along with the actions when the target
    /// should be built.
    public struct Target: Equatable, Codable, Sendable {
        /// Xcode project actions when a build scheme action can build a target.
        public enum BuildFor: Codable, CaseIterable, Sendable {
            case running, testing, profiling, archiving, analyzing
        }

        /// The target reference.
        public var reference: TargetReference

        /// A list of Xcode actions when a target should build.
        public var buildFor: [BuildFor]?

        public init(_ reference: TargetReference, buildFor: [BuildFor]?) {
            self.reference = reference
            self.buildFor = buildFor
        }
    }

    // MARK: - Attributes

    public var targetsWithBuildFor: [Target]
    @available(
        *,
        deprecated,
        renamed: "targetsWithBuildFor",
        message: "Use the initializer that takes targets as instances of BuildAction.Target"
    )
    public var targets: [TargetReference] {
        get {
            targetsWithBuildFor.map(\.reference)
        }
        set {
            targetsWithBuildFor = newValue.map { Target($0, buildFor: nil) }
        }
    }

    public var preActions: [ExecutionAction]
    public var postActions: [ExecutionAction]
    public var runPostActionsOnFailure: Bool

    // MARK: - Init

    @available(*, deprecated, message: "Use the initializer that takes targets as instances of BuildAction.Target")
    public init(
        targets: [TargetReference] = [],
        preActions: [ExecutionAction] = [],
        postActions: [ExecutionAction] = [],
        runPostActionsOnFailure: Bool = false
    ) {
        targetsWithBuildFor = targets.map { Target($0, buildFor: nil) }
        self.preActions = preActions
        self.postActions = postActions
        self.runPostActionsOnFailure = runPostActionsOnFailure
    }

    public init(
        targetsWithBuildFor: [BuildAction.Target] = [],
        preActions: [ExecutionAction] = [],
        postActions: [ExecutionAction] = [],
        runPostActionsOnFailure: Bool = false
    ) {
        self.targetsWithBuildFor = targetsWithBuildFor
        self.preActions = preActions
        self.postActions = postActions
        self.runPostActionsOnFailure = runPostActionsOnFailure
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
