// TargetDependency+Extensions
import XcodeGraph

extension TargetDependency {
  /// Extracts the name of the dependency for relevant cases, such as target, project, SDK, package, and libraries.
  public var name: String {
    switch self {
    case .target(let name, _, _):
      return name
    case .project(let target, _, _, _):
      return target
    case .sdk(let name, _, _):
      return name
    case .package(let product, _, _):
      return product
    case .framework(let path, _, _):
        return path.basenameWithoutExt
    case .xcframework(let path, _, _):
      return path.basenameWithoutExt
    case .library(let path, _, _, _):
      return path.basenameWithoutExt
    case .xctest:
      return "xctest"
    }
  }
}
