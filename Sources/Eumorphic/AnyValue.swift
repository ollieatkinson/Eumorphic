//
//  Created by Oliver Atkinson
//

import Combine

public struct AnyValue: Eumorphic {
    
    public static var empty: AnyValue = .null
    public static var null: AnyValue = .init(nil)
    
    var wrapped: Any {
        didSet { subject.send(wrapped) }
    }
    
    public init(_ value: Any? = nil) {
        wrapped = value.flattened as Any
    }
    
    public func get(_ path: EumorphicPath) throws -> Any {
        try _get(path, from: wrapped)
    }
    
    public mutating func set(_ value: Any, at path: EumorphicPath) throws {
        guard path.isNotEmpty else { return (wrapped = value) }
        wrapped = try _set(value, at: path, on: wrapped)
    }
    
    public var subject = PassthroughSubject<Any, Never>()
}

extension AnyValue {
    
    public func subscribe(to first: EumorphicPath.Key, _ rest: EumorphicPath.Key...) -> AnyPublisher<Result<Any, Error>, Never> {
        subscribe(to: Path([first] + rest))
    }
    
    public func subscribe(to path: EumorphicPath) -> AnyPublisher<Result<Any, Error>, Never> {
        subject.merge(with: Just(wrapped)).map { wrapped in
            return Result { try _get(path, from: wrapped) }
        }.eraseToAnyPublisher()
    }
}

extension AnyValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension AnyValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Any...) {
        self.init(elements)
    }
}

extension AnyValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Any)...) {
        self.init([String: Any].init(elements, uniquingKeysWith: { $1 }))
    }
}

extension AnyValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.init(value)
    }
}

extension AnyValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension AnyValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension AnyValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self.init(value)
    }
}

extension AnyValue: ExpressibleByStringInterpolation {
    public init(stringInterpolation: DefaultStringInterpolation) {
        self.init(stringInterpolation.description)
    }
}

extension AnyValue: Codable {
    
    public init(from decoder: Decoder) throws {
        switch decoder {
        case let decoder as AnyDecoder:
            func ƒ(_ any: Any) throws -> Any {
                switch try decoder.convert(any, to: Any.self) ?? any {
                case let array as [Any]:
                    return try array.enumerated().map { o -> Any in
                        decoder.codingPath.append(AnyCodingKey(o.offset))
                        defer { decoder.codingPath.removeLast() }
                        return try ƒ(o.element)
                    }
                case let dictionary as [String: Any]:
                    return try Dictionary(uniqueKeysWithValues: dictionary.map { o -> (String, Any) in
                        decoder.codingPath.append(AnyCodingKey(o.key))
                        defer { decoder.codingPath.removeLast() }
                        return try (o.key, ƒ(o.value))
                    })
                case let fragment:
                    return fragment
                }
            }
            self = try .init(ƒ(decoder.value))
        case is EmptyDecoder: self = .empty
        default: throw """
            AnyValue can only be decoded with
            AnyDecoder or EmptyDecoder; got: \(decoder)
            """.error()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch encoder {
        case let encoder as AnyEncoder:
            func ƒ(_ any: Any) throws -> Any {
                if let o = try encoder.convert(any) { return o }
                switch any {
                case let array as [Any]: return try array.map(ƒ)
                case let dictionary as [String: Any]: return try dictionary.mapValues(ƒ)
                case let fragment: return fragment
                }
            }
            encoder.value = try ƒ(any())
        default: throw """
            AnyValue can currently only be encoded with a
            StringAnyEncoderProtocol; got: \(encoder)
            """.error()
        }
    }
}

extension AnyValue {

    public func dictionary(_ function: String = #function, _ file: String = #file, _ line: Int = #line) throws -> [String: Any] {
        try (wrapped as? [String: Any]).or(throw: "Expected [String: Any] but got \(type(of: wrapped))".error(function, file, line))
    }
    
    public func array(_ function: String = #function, _ file: String = #file, _ line: Int = #line) throws -> [Any] {
        try (wrapped as? [Any]).or(throw: "Expected [Any] but got \(type(of: wrapped))".error(function, file, line))
    }
    
    public func any() -> Any {
        wrapped
    }
    
}
