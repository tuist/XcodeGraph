import Foundation
@preconcurrency import XcodeGraph

/// Represents the architectures extracted from running `lipo -archs`.
///
/// `LipoArchsResult` provides a structured result indicating which architectures
/// are contained in a given binary. It uses `XcodeGraph.BinaryArchitecture` to
/// represent each architecture (e.g., arm64, x86_64).
public struct LipoArchsResult: Sendable {
    /// The list of architectures reported by `lipo -archs`.
    public let architectures: [XcodeGraph.BinaryArchitecture]
}

/// Parses the output of a `ProcessResult` from a `lipo -archs` invocation into a `LipoArchsResult`.
///
/// `lipo -archs` typically returns a single line of whitespace-separated architectures,
/// for example: `"arm64"` or `"arm64 x86_64"`.
///
/// - Parameter result: The `ProcessResult` obtained from running the `lipo -archs` command.
/// - Returns: A `LipoArchsResult` containing all detected architectures.
/// - Throws:
///   - `ProcessRunnerError.failedToRunProcess` if `lipo` exits with a non-zero code.
///   - Any errors related to decoding or interpreting the output as architectures.
public func parseLipoArchsResult(_ result: ProcessResult) throws -> LipoArchsResult {
    // Ensure that the process succeeded. If not, throw an error indicating lipo failed.
    guard result.succeeded else {
        throw ProcessRunnerError.failedToRunProcess("Lipo returned non-zero exit code.")
    }

    // Trim whitespace and split by space to extract architecture identifiers.
    let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    let archs = output.split(separator: " ")
        .map(String.init)
        .compactMap(BinaryArchitecture.init)

    // Return the parsed architectures encapsulated in a LipoArchsResult.
    return LipoArchsResult(architectures: archs)
}
