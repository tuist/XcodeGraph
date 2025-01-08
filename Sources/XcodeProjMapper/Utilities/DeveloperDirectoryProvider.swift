import Command
import Foundation
import Path

/// A protocol that obtains the current developer directory (via `xcode-select -p`) asynchronously.
public protocol DeveloperDirectoryProviding {
    /// Returns the absolute path to the currently selected Xcode’s Developer directory.
    /// - Throws: If `xcode-select -p` fails or if the output is invalid.
    func developerDirectory() async throws -> AbsolutePath
}

public struct DeveloperDirectoryProvider: DeveloperDirectoryProviding {
    private let commandRunner: CommandRunning

    public init(commandRunner: CommandRunning = CommandRunner()) {
        self.commandRunner = commandRunner
    }

    /// Uses `xcode-select -p` to get the path to the currently selected Xcode’s Developer folder,
    /// concatenates stdout data into a single string, and returns it.
    public func developerDirectory() async throws -> AbsolutePath {
        let stream = commandRunner.run(arguments: ["xcode-select", "-p"])
        let path = try await stream.concatenatedString().trimmingCharacters(in: .whitespacesAndNewlines)
        return try AbsolutePath(validating: path)
    }
}
