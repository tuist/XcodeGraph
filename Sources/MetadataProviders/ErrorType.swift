import Foundation

/// Error type.
///
/// - abort: error thrown when an unexpected condition happens.
/// - bug: error thrown when a bug is found and the execution cannot continue.
/// - abortSilent: like abort but without printing anything to the user.
/// - bugSilent: like bug but without printing anything to the user.
public enum ErrorType: Sendable {
    case abort
    case bug
    case abortSilent
    case bugSilent
}

/// Fatal error protocol.
public protocol FatalError: Error, CustomStringConvertible {
    /// Error type.
    var type: ErrorType { get }
}
