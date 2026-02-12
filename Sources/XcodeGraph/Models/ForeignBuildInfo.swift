import Path

public struct ForeignBuildInfo: Equatable, Hashable, Codable, Sendable {
    public let script: String
    public let inputs: [ForeignBuildInput]
    public let output: ForeignBuildArtifact

    public init(
        script: String,
        inputs: [ForeignBuildInput],
        output: ForeignBuildArtifact
    ) {
        self.script = script
        self.inputs = inputs
        self.output = output
    }
}
