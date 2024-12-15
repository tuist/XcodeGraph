import Foundation

public class MockFileCreator {
  public static func createTemporaryExecutable(
    name: String = "mockLipo_\(UUID().uuidString)",
    withContent content: String
  ) throws -> String {
    let tempDirectory = FileManager.default.temporaryDirectory
    let mockExecutablePath = tempDirectory.appendingPathComponent(name).path

    try content.write(toFile: mockExecutablePath, atomically: true, encoding: .utf8)

    try FileManager.default.setAttributes(
      [.posixPermissions: 0o755], ofItemAtPath: mockExecutablePath)

    return mockExecutablePath
  }
}
