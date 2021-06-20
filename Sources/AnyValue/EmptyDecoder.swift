//
//  Created by Milos Rankovic
//  Adapted by Oliver Atkinson
//

import Foundation

protocol EmptyInit { init() }

extension Data: EmptyInit {}
extension Bool: EmptyInit {}
extension Int: EmptyInit {}
extension Float: EmptyInit {}
extension Double: EmptyInit {}
extension String: EmptyInit {}
extension Date: EmptyInit {}

extension Optional: EmptyInit {
    public init() { self = .none }
}

extension Array: EmptyInit {}
extension Dictionary: EmptyInit {}

extension URL: EmptyInit {
    public init() { self.init(string: "https")! }
}

extension AnyValue: EmptyInit {
    public init() { self = .empty }
}

extension Decodable {
    
    public static func empty() throws -> Self {
        if let empty = self as? EmptyInit.Type, let `init` = empty.init() as? Self {
            return `init`
        }
        return try Self(from: EmptyDecoder())
    }
}

public struct EmptyDecoder: Decoder {
    
    public  let codingPath: [CodingKey] = [ ]
    public let userInfo: [CodingUserInfoKey: Any] = [:]
    
    public func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> { .init(Keyed<Key>()) }
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer { Unkeyed() }
    public func singleValueContainer() throws -> SingleValueDecodingContainer { SingleValue() }
    
    public struct Keyed<Key: CodingKey>: KeyedDecodingContainerProtocol {
        
        public let allKeys: [Key] = []
        public let codingPath: [CodingKey] = []
        
        public func contains(_ key: Key) -> Bool { true }
        public func decodeNil(forKey key: Key) throws -> Bool { true }
        public func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T { try T.empty() }
        
        public func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> { .init(Keyed<NestedKey>()) }
        public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer { Unkeyed() }
        public func superDecoder() throws -> Decoder { EmptyDecoder() }
        public func superDecoder(forKey key: Key) throws -> Decoder { EmptyDecoder() }
        
    }
    
    public struct Unkeyed: UnkeyedDecodingContainer {
        
        public let codingPath: [CodingKey] = [ ]
        public var isAtEnd: Bool { true }
        public var count: Int? = 0
        public var currentIndex: Int = 0
        
        public mutating func decodeNil() throws -> Bool { true }
        public mutating func decode<T: Decodable>(_ type: T.Type) throws -> T { try T.empty() }
        
        public mutating func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> { .init(Keyed<NestedKey>()) }
        public mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer { Unkeyed() }
        public mutating func superDecoder() throws -> Decoder { EmptyDecoder() }
    }
    
    public struct SingleValue: SingleValueDecodingContainer {
        
        public let codingPath: [CodingKey] = [ ]
        
        public func decodeNil() -> Bool { return true }
        public func decode<T: Decodable>(_ type: T.Type) throws -> T { return try T.empty() }
    }
}