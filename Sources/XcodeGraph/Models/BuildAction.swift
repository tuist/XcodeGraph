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

        public init(_ reference: TargetReference, buildFor: [BuildFor]? = nil) {
            self.reference = reference
            self.buildFor = buildFor
        }
    }

    // MARK: - Attributes

    public var targets: [Target]
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
        self.targets = targets.map { Target($0, buildFor: nil) }
        self.preActions = preActions
        self.postActions = postActions
        self.runPostActionsOnFailure = runPostActionsOnFailure
    }

    public init(
        targets: [BuildAction.Target] = [],
        preActions: [ExecutionAction] = [],
        postActions: [ExecutionAction] = [],
        runPostActionsOnFailure: Bool = false
    ) {
        self.targets = targets
        self.preActions = preActions
        self.postActions = postActions
        self.runPostActionsOnFailure = runPostActionsOnFailure
    }
}

#if DEBUG
    extension BuildAction.Target {
        public static func test(_ reference: TargetReference = TargetReference.test(), buildFor: [BuildFor]? = nil) -> Self {
            return Self(reference, buildFor: buildFor)
        }
    }

    extension BuildAction {
        public static func test(
            // swiftlint:disable:next force_try
            targets: [BuildAction.Target] = [],
            preActions: [ExecutionAction] = [],
            postActions: [ExecutionAction] = []
        ) -> BuildAction {
            BuildAction(targets: targets, preActions: preActions, postActions: postActions)
        }
    }
#endif
