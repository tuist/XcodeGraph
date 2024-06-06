import Foundation
import Path
@testable import XcodeGraph

extension BuildAction {
    public static func test(
        targets: [TargetReference] = [TargetReference(projectPath: try! AbsolutePath(validating: "/Project"), name: "App")],
        preActions: [ExecutionAction] = [],
        postActions: [ExecutionAction] = []
    ) -> BuildAction {
        BuildAction(targets: targets, preActions: preActions, postActions: postActions)
    }
}
