import Foundation

public typealias Destinations = Set<Destination>

extension Destinations {
    public static let watchOS: Destinations = [.appleWatch]
    public static let iOS: Destinations = [.iPhone, .iPad, .macWithiPadDesign]
    public static let macOS: Destinations = [.mac]
    public static let tvOS: Destinations = [.appleTv]
    public static let visionOS: Destinations = [.appleVision]
}

extension Destinations {
    public var platforms: Set<Platform> {
        let platforms = map(\.platform)
        return Set<Platform>(platforms)
    }
}

/// A supported platform representation.
public enum Destination: String, Codable, Equatable, CaseIterable, Sendable {
    case iPhone
    case iPad
    case mac
    case macWithiPadDesign
    case macCatalyst
    case appleWatch
    case appleTv
    case appleVision
    case appleVisionWithiPadDesign

    public var platform: Platform {
        switch self {
        case .iPad, .iPhone, .macCatalyst, .macWithiPadDesign, .appleVisionWithiPadDesign:
            return .iOS
        case .mac:
            return .macOS
        case .appleTv:
            return .tvOS
        case .appleWatch:
            return .watchOS
        case .appleVision:
            return .visionOS
        }
    }

    public var platformFilter: PlatformFilter {
        switch self {
        case .iPad, .iPhone, .macWithiPadDesign, .appleVisionWithiPadDesign:
            return .ios
        case .macCatalyst:
            return .catalyst
        case .mac:
            return .macos
        case .appleTv:
            return .tvos
        case .appleWatch:
            return .watchos
        case .appleVision:
            return .visionos
        }
    }
}

extension Collection<Destination> {
    public func supports(_ platform: Platform) -> Bool {
        contains(where: { $0.platform == platform })
    }
}
