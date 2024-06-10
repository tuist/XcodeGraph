import Foundation
import Path

public struct BuildAction: Equatable, Codable {
    // MARK: - Attributes

    public var targets: [TargetReference]
    public var preActions: [ExecutionAction]
    public var postActions: [ExecutionAction]
    public var runPostActionsOnFailure: Bool

    // MARK: - Init

    public init(
        targets: [TargetReference] = [],
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
