import XcodeGraph
import XcodeProj

/// A mapper for platform-related conditions, extracting platform filters from `PBXTargetDependency`.
public enum PlatformConditionMapper {
    /// Maps the platform filters on a given `PBXTargetDependency` into a `PlatformCondition`.
    ///
    /// Returns `nil` if no filters apply, meaning the dependency isn't restricted by platform and
    /// should be considered available on all platforms.
    public static func mapCondition(dependency: PBXTargetDependency) -> PlatformCondition? {
        var filters = Set(dependency.platformFilters ?? [])
        if let singleFilter = dependency.platformFilter {
            filters.insert(singleFilter)
        }

        let platformFilters = Set(filters.compactMap { PlatformFilter(rawValue: $0) })
        return PlatformCondition.when(platformFilters)
    }
}
