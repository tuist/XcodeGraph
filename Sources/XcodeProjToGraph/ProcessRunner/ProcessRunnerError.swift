import Foundation

public enum ProcessRunnerError: Error, LocalizedError, Equatable {
  case executableNotFound(String)
  case failedToRunProcess(String)
  case invalidUTF8InOutput
  case nonZeroExitCode(Int32, String)

  public var errorDescription: String? {
    switch self {
    case .executableNotFound(let cmd):
      return "The executable '\(cmd)' was not found or is not executable."
    case .failedToRunProcess(let reason):
      return "Failed to run process: \(reason)"
    case .invalidUTF8InOutput:
      return "Could not decode output as UTF-8."
    case let .nonZeroExitCode(code, stderr):
      return "Command exited with code \(code). Stderr: \(stderr)"
    }
  }
}
