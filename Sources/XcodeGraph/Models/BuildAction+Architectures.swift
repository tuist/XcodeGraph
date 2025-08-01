extension BuildAction {
    public enum Architectures: Equatable, Codable, Sendable {
        case matchRunDestination
        case universal
        case useTargetSettings
    }
}
