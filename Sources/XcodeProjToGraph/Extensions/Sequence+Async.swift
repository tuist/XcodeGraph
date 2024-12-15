import Foundation

extension Sequence where Element: Sendable {
    func asyncCompactMap<T: Sendable>(_ transform: @escaping @Sendable (Element) async throws -> T?)
        async throws -> [T]
    {
        var results = [T]()
        try await withThrowingTaskGroup(of: T?.self) { group in
            for element in self {
                group.addTask {
                    try await transform(element)
                }
            }

            for try await value in group {
                if let value {
                    results.append(value)
                }
            }
        }

        return results
    }
}
