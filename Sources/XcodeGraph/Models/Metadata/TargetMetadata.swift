/// The metadata associated with a target.
public struct TargetMetadata: Codable, Equatable, Sendable {
    /// Tags set by the user to group targets together.
    /// Some Tuist features can leverage that information for doing things like filtering.
    public var tags: Set<String>

    /// Whether the target redundant dependencies should be ignored during `tuist inspect redundant-import`
    public var ignoreRedundantDependencies: Bool

    @available(*, deprecated, renamed: "metadata(tags:)", message: "Use the static 'metadata' initializer instead")
    public init(
        tags: Set<String>
    ) {
        self.init(tags: tags, isLocal: false, ignoreRedundantDependencies: false)
    }

    init(tags: Set<String>, isLocal _: Bool, ignoreRedundantDependencies: Bool) {
        self.tags = tags
        self.ignoreRedundantDependencies = ignoreRedundantDependencies
    }

    public static func metadata(
        tags: Set<String> = Set(),
        isLocal: Bool = true,
        ignoreRedundantDependencies: Bool = false
    ) -> TargetMetadata {
        self.init(tags: tags, isLocal: isLocal, ignoreRedundantDependencies: ignoreRedundantDependencies)
    }
}

#if DEBUG
    extension TargetMetadata {
        public static func test(
            tags: Set<String> = [],
            ignoreRedundantDependencies: Bool = false
        ) -> TargetMetadata {
            TargetMetadata.metadata(
                tags: tags,
                ignoreRedundantDependencies: ignoreRedundantDependencies
            )
        }
    }
#endif
