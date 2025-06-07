@preconcurrency import AnyCodable
import Foundation
import Path

public struct ResourceSynthesizer: Equatable, Hashable, Codable, Sendable {
    public let parser: Parser
    public let parserOptions: [String: Parser.Option]
    public let extensions: Set<String>
    public let template: Template
    public let templateParameters: [String: Template.Parameter]

    public enum Template: Equatable, Hashable, Codable, Sendable {
        case file(AbsolutePath)
        case defaultTemplate(String)

        public enum Parameter: Equatable, Hashable, Codable, Sendable {
            case string(String)
            case integer(Int)
            case double(Double)
            case boolean(Bool)
            case dictionary([String: Parameter])
            case array([Parameter])
        }
    }

    public enum Parser: String, CaseIterable, Equatable, Hashable, Codable, Sendable {
        case strings
        case stringsCatalog
        case assets
        case plists
        case fonts
        case coreData
        case interfaceBuilder
        case json
        case yaml
        case files

        public struct Option: Equatable, Hashable, Codable, Sendable {
            public var value: Any { anyCodableValue.value }
            private let anyCodableValue: AnyCodable

            public init(value: some Any) {
                anyCodableValue = AnyCodable(value)
            }
        }
    }

    public init(
        parser: Parser,
        parserOptions: [String: Parser.Option],
        extensions: Set<String>,
        template: Template,
        templateParameters: [String: Template.Parameter]
    ) {
        self.parser = parser
        self.parserOptions = parserOptions
        self.extensions = extensions
        self.template = template
        self.templateParameters = templateParameters
    }
}

// MARK: - ResourceSynthesizer.Template.Parameter - ExpressibleByStringInterpolation

extension ResourceSynthesizer.Template.Parameter: ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

// MARK: - ResourceSynthesizer.Template.Parameter - ExpressibleByIntegerLiteral

extension ResourceSynthesizer.Template.Parameter: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .integer(value)
    }
}

// MARK: - ResourceSynthesizer.Template.Parameter - ExpressibleByFloatLiteral

extension ResourceSynthesizer.Template.Parameter: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

// MARK: - ResourceSynthesizer.Template.Parameter - ExpressibleByBooleanLiteral

extension ResourceSynthesizer.Template.Parameter: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .boolean(value)
    }
}

// MARK: - ResourceSynthesizer.Template.Parameter - ExpressibleByDictionaryLiteral

extension ResourceSynthesizer.Template.Parameter: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Self)...) {
        self = .dictionary(Dictionary(uniqueKeysWithValues: elements))
    }
}

// MARK: - ResourceSynthesizer.Template.Parameter - ExpressibleByArrayLiteral

extension ResourceSynthesizer.Template.Parameter: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Self...) {
        self = .array(elements)
    }
}

// MARK: - ResourceSynthesizer.Parser.Option - ExpressibleByStringInterpolation

extension ResourceSynthesizer.Parser.Option: ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self = .init(value: value)
    }
}

// MARK: - ResourceSynthesizer.Parser.Option - ExpressibleByIntegerLiteral

extension ResourceSynthesizer.Parser.Option: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .init(value: value)
    }
}

// MARK: - ResourceSynthesizer.Parser.Option - ExpressibleByFloatLiteral

extension ResourceSynthesizer.Parser.Option: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .init(value: value)
    }
}

// MARK: - ResourceSynthesizer.Parser.Option - ExpressibleByBooleanLiteral

extension ResourceSynthesizer.Parser.Option: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .init(value: value)
    }
}

// MARK: - ResourceSynthesizer.Parser.Option - ExpressibleByDictionaryLiteral

extension ResourceSynthesizer.Parser.Option: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Self)...) {
        self = .init(value: Dictionary(uniqueKeysWithValues: elements))
    }
}

// MARK: - ResourceSynthesizer.Parser.Option - ExpressibleByArrayLiteral

extension ResourceSynthesizer.Parser.Option: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Self...) {
        self = .init(value: elements)
    }
}

#if DEBUG
    extension XcodeGraph.ResourceSynthesizer {
        public static func test(
            parser: Parser = .assets,
            parserOptions: [String: Parser.Option] = [:],
            extensions: Set<String> = ["xcassets"],
            template: Template = .defaultTemplate("Assets"),
            templateParameters: [String: Template.Parameter] = [:]
        ) -> Self {
            ResourceSynthesizer(
                parser: parser,
                parserOptions: parserOptions,
                extensions: extensions,
                template: template,
                templateParameters: templateParameters
            )
        }
    }
#endif
