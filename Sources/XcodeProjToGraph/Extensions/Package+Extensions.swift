import XcodeGraph

extension Package {
  /// Returns a URL or identifier for the package based on whether it's remote or local.
  public var url: String {
    switch self {
    case .remote(let url, _):
      return url
    case .local(let path):
      return path.pathString
    }
  }
}
