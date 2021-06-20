//
//  Created by Milos Rankovic
//  Adapted by Oliver Atkinson
//

import Combine
import CoreGraphics
import Foundation

protocol AnyDecoderProtocol: AnyObject, Decoder {
    var value: Any { get set }
    var codingPath: [CodingKey] { get set }
    init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any])
    
    func decode<T>(_: T.Type, from any: Any) throws -> T where T: Decodable
    func convert<T>(_ any: Any, to: T.Type) throws -> Any?
}

open class AnyDecoder: AnyDecoderProtocol {
    
    public var codingPath: [CodingKey] = [ ]
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    public var value: Any = NSNull()
    
    public required init(codingPath: [CodingKey] = [], userInfo: [CodingUserInfoKey: Any] = [:]) {
        self.codingPath = codingPath
        self.userInfo = userInfo
    }
    
    public func decode<T>(_: T.Type = T.self, from any: Any) throws -> T where T: Decodable {
        let old = value
        value = any
        defer { value = old }
        do {
            if let o = T.self as? OptionalDecodableProtocol.Type {
                return o.decodeUnwrapped(from: self) as! T
            }
            if let optional = any as? FlattenOptional {
                guard let value = optional.flattened else { throw valueNotFound(T.self) }
                return try decode(T.self, from: value)
            } else if let o = try convert(any, to: T.self) as? T {
                return o
            }
            return try T(from: self)
        } catch {
            return try any as? T ?? ((T.self as? FlattenOptional.Type)?.null as? T).or(throw: error)
        }
    }
    
    public func decode<T>(_: T?.Type = T?.self, from any: Any) -> T? where T: Decodable {
        try? decode(T.self, from: any)
    }
    
    open func convert<T>(_ any: Any, to type: T.Type) throws -> Any? {
        switch (any, T.self) {
        case let (time as TimeInterval, is Date.Type):
            return Date(timeIntervalSince1970: time)
        case let (string as String, is URL.Type):
            return try URL(string: string).or(throw: "'\(string)' is not a URL".error())
        case let (number as NSNumber, is Bool.Type):
            return number.boolValue
        case let (number as NSNumber, is Int.Type):
            return number.intValue
        case let (number as NSNumber, is UInt.Type):
            return number.uintValue
        case let (number as NSNumber, is Float.Type):
            return number.floatValue
        case let (number as NSNumber, is Double.Type):
            return number.doubleValue
        case let (number as NSNumber, is CGFloat.Type):
            return number.doubleValue
        default:
            return nil
        }
    }
}

extension AnyDecoder {
    
    func valueNotFound<T>(_: T.Type, _ function: String = #function, _ file: String = #file, _ line: Int = #line) -> Error {
        "Value of type \(T.self) not found at coding path /\(codingPath.string); found \(Swift.type(of: value))".error(function, file, line)
    }
}

extension AnyDecoder {
    
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        try KeyedDecodingContainer(KeyedContainer<Key>(decoder: self))
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        try UnkeyedContainer(decoder: self)
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        try SingleValueContainer(decoder: self)
    }
}

extension AnyDecoder {
    
    public struct KeyedContainer<Key> where Key: CodingKey {
        
        let decoder: AnyDecoder
        public let dictionary: [String: Any]
        
        public var codingPath: [CodingKey] { decoder.codingPath }
        public var userInfo: [CodingUserInfoKey: Any] { decoder.userInfo}
        
        public init(decoder: AnyDecoder) throws {
            self.decoder = decoder
            self.dictionary = try (decoder.value as? Dictionary).or(throw: "Expected a [String: Any] but got: \(decoder.value)".error())
        }
        
        public func value(for key: Key) throws -> Any {
            try dictionary[key.stringValue].or(throw: "No value found for key '\(key.stringValue)'".error())
        }
    }
}

extension AnyDecoder.KeyedContainer: KeyedDecodingContainerProtocol {
    
    public var allKeys: [Key] {
        dictionary.keys.compactMap(Key.init)
    }
    
    public func contains(_ key: Key) -> Bool {
        dictionary[key.stringValue] != nil
    }
    
    public func decodeNil(forKey key: Key) throws -> Bool {
        isNil(dictionary[key.stringValue])
    }
    
    public func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        let value = try self.value(for: key)
        decoder.codingPath.append(^key.stringValue)
        defer { decoder.codingPath.removeLast() }
        return try decoder.decode(from: value)
    }
}

extension AnyDecoder {
    
    public struct SingleValueContainer {
        
        public let decoder: AnyDecoder
        public let value: Any
        
        public var codingPath: [CodingKey] { decoder.codingPath }
        public var userInfo: [CodingUserInfoKey: Any] { decoder.userInfo}
        
        public init(decoder: AnyDecoder) throws {
            self.decoder = decoder
            self.value = decoder.value
        }
    }
}

extension AnyDecoder.SingleValueContainer: SingleValueDecodingContainer {
    
    public func decodeNil() -> Bool {
        isNil(value)
    }

    public func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        guard type.containerType == .singleValue else {
            return try decoder.decode(from: value)
        }
        return try (value as? T).or(throw: decoder.valueNotFound(T.self))
    }
}

extension AnyDecoder {
    
    public struct UnkeyedContainer {

        public let array: [Any]
        public let decoder: AnyDecoder
        
        public var count: Int? { array.count }
        private(set) public var currentIndex: Int = 0
        
        public var codingPath: [CodingKey] { decoder.codingPath }
        public var userInfo: [CodingUserInfoKey: Any] { decoder.userInfo}
        
        public init(decoder: AnyDecoder) throws {
            self.decoder = decoder
            self.array = try (decoder.value as? Array).or(throw: "Expected a [Any] but got: \(decoder.value)".error())
        }
    }
}

extension AnyDecoder.UnkeyedContainer: UnkeyedDecodingContainer {

    public var isAtEnd: Bool { currentIndex == count }

    public mutating func decodeNil() throws -> Bool {
        let null = isNil(array[currentIndex])
        defer { currentIndex += null ? 1 : 0 }
        return null
    }
    
    public mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        defer { currentIndex += 1 }
        decoder.codingPath.append(^currentIndex)
        defer { decoder.codingPath.removeLast() }
        return try decoder.decode(from: array[currentIndex])
    }
}

private func unsupported(_ function: String = #function) -> Never {
    fatalError("\(function) isn't supported by AnyDecoder")
}

extension AnyDecoder.KeyedContainer {
    public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer { unsupported() }
    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey { unsupported() }
    public func superDecoder() throws -> Decoder { unsupported() }
    public func superDecoder(forKey key: Key) throws -> Decoder { unsupported() }
}

extension AnyDecoder.UnkeyedContainer {
    public mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer { unsupported() }
    public mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey { unsupported() }
    public mutating func superDecoder() throws -> Decoder { unsupported() }
}

extension Sequence where Element == CodingKey {
    var string: String {
        map(\.stringValue).joined(separator: "/")
    }
}

fileprivate protocol OptionalDecodableProtocol: FlattenOptional, Decodable {
    static func decodeUnwrapped<D: AnyDecoderProtocol>(from decoder: D) -> Self
}

extension Optional: OptionalDecodableProtocol where Wrapped: Decodable & Equatable {
    static func decodeUnwrapped<D: AnyDecoderProtocol>(from decoder: D) -> Optional {
        return try? decoder.decode(Wrapped.self, from: decoder.value)
    }
}
