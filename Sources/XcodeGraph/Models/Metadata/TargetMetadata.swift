/// The metadata associated with a target.
public struct TargetMetadata: Codable, Equatable, Sendable {
    /// Tags set by the user to group targets together.
    /// Some Tuist features can leverage that information for doing things like filtering.
    public var tags: Set<String>

    /// Projects can be external or not, which means they are declared or not using the Tuist Projects' DSL
    /// and the targets of those projects can fall into two categories:
    ///   - Local:  They've been linked from a local directory (e.g., a local package)
    ///   - Remote: They've been resolved and pulled by a package manager (e.g. SPM)
    public var isLocal: Bool

    @available(*, deprecated, renamed: "metadata(tags:)", message: "Use the static 'metadata' initializer instead")
    public init(
        tags: Set<String>
    ) {
        self.tags = tags
        isLocal = true
    }

    init(tags: Set<String>, isLocal: Bool) {
        self.tags = tags
        self.isLocal = isLocal
    }

    public static func metadata(tags: Set<String> = Set(), isLocal: Bool = true) -> TargetMetadata {
        self.init(tags: tags, isLocal: isLocal)
    }
}

#if DEBUG
    extension TargetMetadata {
        public static func test(
            tags: Set<String> = [],
            isLocal: Bool = true
        ) -> TargetMetadata {
            TargetMetadata.metadata(
                tags: tags,
                isLocal: isLocal
            )
        }
    }
#endif
