import Foundation

/// A type that indicates where the project is coming from.
public enum ProjectType: Codable {
    case remotePackage
    case localPackage
    case tuistProject
}
