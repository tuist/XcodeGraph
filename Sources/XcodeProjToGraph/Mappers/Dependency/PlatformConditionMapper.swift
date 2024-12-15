import XcodeGraph
import XcodeProj

/// A mapper for platform-related conditions, extracting platform filters from `PBXTargetDependency`.
enum PlatformConditionMapper {
  /// Maps the platform filters specified on a `PBXTargetDependency` into a `PlatformCondition`.
  ///
  /// - Parameter dependency: The `PBXTargetDependency` to inspect.
  /// - Returns: A `PlatformCondition` representing the platforms this dependency applies to, or `nil` if none.
  static public func mapCondition(dependency: PBXTargetDependency) -> PlatformCondition? {
    var filters = Set(dependency.platformFilters ?? [])
    if let singleFilter = dependency.platformFilter {
      filters.insert(singleFilter)
    }

    let platformFilters = Set(filters.compactMap { PlatformFilter(rawValue: $0) })
    return PlatformCondition.when(platformFilters)
  }
}
