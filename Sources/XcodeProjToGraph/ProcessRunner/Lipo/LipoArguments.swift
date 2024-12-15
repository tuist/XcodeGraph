import Foundation

public struct LipoArguments: Sendable {
    public enum Operation: Sendable {
        case archs

        public var command: String {
            switch self {
            case .archs:
                "-archs"
            }
        }
    }

    public let operation: Operation
    public let paths: [String]

    public init(operation: Operation, paths: [String]) {
        self.operation = operation
        self.paths = paths
    }

    func toArguments() -> [String] {
        var args: [String] = []
        args.append(operation.command)
        args.append(contentsOf: paths)
        return args
    }
}
