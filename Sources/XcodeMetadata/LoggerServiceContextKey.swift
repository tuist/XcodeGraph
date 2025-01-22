import Logging
import ServiceContextModule

private enum LoggerServiceContextKey: ServiceContextKey {
    typealias Value = Logger
}

extension ServiceContext {
    var logger: Logger? {
        get {
            self[LoggerServiceContextKey.self]
        } set {
            self[LoggerServiceContextKey.self] = newValue
        }
    }
}
