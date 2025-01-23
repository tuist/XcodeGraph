
import Foundation

/// A type-erased `Codable` value. This can decode values of various primitive
/// types and containers (e.g. arrays, dictionaries) into a Swift-friendly format.
public enum AnyCodable: Codable, Equatable {
    case bool(Bool)
    case string(String)
    case int(Int)
    case double(Double)
    case array([AnyCodable])
    case dictionary([String: AnyCodable])
    case null
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try decoding in priority order (common → complex)
        if container.decodeNil() {
            self = .null
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            self = .array(arrayValue)
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            self = .dictionary(dictValue)
        } else {
            // If you reach here, it means the value isn't one of our recognized formats.
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable: encountered an unrecognized type."
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .array(let array):
            try container.encode(array)
        case .dictionary(let dict):
            try container.encode(dict)
        case .null:
            try container.encodeNil()
        }
    }
}
