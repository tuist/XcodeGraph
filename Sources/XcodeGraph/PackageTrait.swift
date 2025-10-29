public struct PackageTrait: Equatable, Hashable, Codable {
    /// The list of traits that are enabled by default.
    public let enabledTraits: [String]

    /// The name of the trait. When a trait just includes enabled traits, this name takes the value of "default"
    public let name: String

    /// Trait description
    public let description: String?
}
