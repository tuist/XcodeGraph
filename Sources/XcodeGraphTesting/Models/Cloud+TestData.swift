import Foundation
import Path
@testable import XcodeGraph

extension Cloud {
    public static func test(
        url: URL = URL(string: "https://cloud.tuist.io")!,
        projectId: String = "123",
        options: [Cloud.Option] = []
    ) -> Cloud {
        Cloud(url: url, projectId: projectId, options: options)
    }
}
