//
//  Created by Oliver Atkinson
//

import Foundation

prefix operator ^

extension HeterogeneousContainerProtocol {
    public typealias Path = AnyPath
}

public struct AnyPath: Collection {
    
    public enum Key {
        case int(Int), string(String)
    }
    
    public typealias Base = AnyRandomAccessCollection<Key>
    public typealias Index = Base.Index
    
    let base: Base
    
    public init<C>(_ codingPath: C) where C: RandomAccessCollection, C.Element == CodingKey {
        self.base = AnyRandomAccessCollection(codingPath.map { key in
            if let idx = key.intValue {
                return ^idx
            } else {
                return ^key.stringValue
            }
        })
    }
    
    public init<C>(_ codingPath: C) where C: RandomAccessCollection, C.Element: CodingKey {
        self.init(codingPath.lazy.map{ $0 as CodingKey })
    }
    
    public init<C>(_ base: C) where C: RandomAccessCollection, C.Element == Key {
        self.base = AnyRandomAccessCollection(base)
    }
}

extension AnyPath: ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: Key...) {
        self.init(elements)
    }
    
    public init(arrayLiteral elements: CodingKey...) {
        self.init(elements)
    }
}

extension AnyPath {
    
    public var startIndex: Index { base.startIndex }
    public var endIndex: Index { base.endIndex }
    
    public func index(after i: Index) -> Index {
        base.index(after: i)
    }
    public func index(_ i: Base.Index, offsetBy distance: Int) -> Base.Index {
        base.index(i, offsetBy: distance)
    }
    public func index(_ i: Base.Index, offsetBy distance: Int, limitedBy limit: Base.Index) -> Base.Index? {
        base.index(i, offsetBy: distance, limitedBy: limit)
    }
    public func distance(from start: Base.Index, to end: Base.Index) -> Int {
        base.distance(from: start, to: end)
    }
    public subscript(position: Base.Index) -> (head: Key, tail: AnyPath) {
        return (base[position], AnyPath(base.suffix(from: index(after: position))))
    }
}

extension AnyPath {
    
    public func appending(_ other: AnyPath.Key) -> AnyPath {
        AnyPath([crumb, AnyRandomAccessCollection([other])].flatMap{ $0 })
    }
    
    public func appending(_ path: AnyPath) -> AnyPath {
        AnyPath([crumb, path.crumb].flatMap{ $0 })
    }
}

extension AnyPath {
    public var isNotEmpty: Bool { !isEmpty }
    public var crumb: AnyRandomAccessCollection<Key> { base }
}

extension AnyPath: BidirectionalCollection {
    
    public func index(before i: Base.Index) -> Base.Index {
        base.index(before: i)
    }
}

extension AnyPath: RandomAccessCollection {}
extension AnyPath: LazySequenceProtocol {}
extension AnyPath: LazyCollectionProtocol {}
extension AnyPath: Equatable {
    
    public static func == (lhs: AnyPath, rhs: AnyPath) -> Bool {
        lhs.base.elementsEqual(rhs.base)
    }
}
extension AnyPath: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        for o in base {
            hasher.combine(o)
        }
    }
}

extension AnyPath: Codable {
    
    public init(from decoder: Decoder) throws {
        let string = try String(from: decoder)
        self = try Self.init(string).or(throw: "Could not create path from \(string)".error())
    }
    
    public func encode(to encoder: Encoder) throws {
        try string.encode(to: encoder)
    }
}

extension AnyPath.Key {
    public static var first: Self { ^(0) }
    public static var last: Self { ^(-1) }
}

extension AnyPath.Key {
    static func string(_ string: Substring) -> Self {
        .string(string.string)
    }
}

extension AnyPath.Key: CodingKey, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
    
    public init(stringLiteral value: String) {
        self = .string(value)
    }
    
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
    
    public var stringValue: String {
        switch self {
        case let .int(o): return "\(o)"
        case let .string(o): return o
        }
    }
    
    public init?(stringValue: String) {
        self = .string(stringValue)
    }
    
    public var intValue: Int? {
        switch self {
        case let .int(o): return o
        case .string: return nil
        }
    }
    
    public init?(intValue: Int) {
        self = .int(intValue)
    }
    
}

extension AnyPath.Key: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .int(i): hasher.combine(i)
        case let .string(s): hasher.combine(s)
        }
    }
    
    public static func == (lhs: AnyPath.Key, rhs: AnyPath.Key) -> Bool {
        switch (lhs, rhs) {
        case let (.int(i), .int(j)): return i == j
        case let (.string(i), .string(j)): return i == j
        default: return false
        }
    }
    
}

public prefix func ^ (r: Int) -> AnyPath.Key { .int(r) }
public prefix func ^ <S>(r: S) -> AnyPath.Key where S: StringProtocol { .string(r.string) }

extension AnyPath.Key: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .int(let o): return o.description
        case .string(let o): return o
        }
    }
}

extension AnyPath.Key {
    
    public var isInt: Bool {
        switch self {
        case .int: return true
        case .string: return false
        }
    }
    
    public var isString: Bool {
        switch self {
        case .int: return false
        case .string: return true
        }
    }
}

extension AnyPath.Key {
    
    public init(_ string: String) {
        self = .string(string)
    }
    
    public init(_ int: Int) {
        self = .int(int)
    }
}

extension AnyPath.Key: Codable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            let value = try container.decode(Int.self)
            self = .int(value)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value): try container.encode(value)
        case let .int(value): try container.encode(value)
        }
    }
}

extension String {
    
    fileprivate subscript(ns: NSRange) -> SubSequence {
        guard let range = Range<String.Index>(ns, in: self) else { fatalError("Out of bounds") }
        return self[range]
    }
}

extension StringProtocol {
    fileprivate var string: String { String(self) }
}

extension AnyPath: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.init(value)!
    }
}

extension AnyPath: LosslessStringConvertible {
    
    public static let pattern = try! NSRegularExpression(pattern: #"\.?((?<name>[\w]+)|\[(?<idx>[\d]+)\])"#)
    
    public init?(_ description: String) {
        do {
            self = try Self(AnyPath.pattern.matches(in: description, range: NSRange(description.startIndex..<description.endIndex, in: description)).map { match in
                
                let range = (
                    name: match.range(withName: "name"),
                    idx: match.range(withName: "idx")
                )
                
                switch (range.name.location, range.idx.location) {
                case (0..<NSNotFound, NSNotFound) :
                    return .string(description[range.name].string)
                case (NSNotFound, 0..<NSNotFound) :
                    guard let idx = Int(description[range.idx]) else {
                        throw "Invalid crumb sequence for array index, expected integer but got. \(description[range.idx])".error()
                    }
                    return .int(idx)
                default:
                    throw "Invalid crumb sequence, expected string or integer and got neither. \(description)[\(match.range)]".error()
                }
            })
        } catch {
            return nil
        }
    }
    
    public var string: String {
        base.enumerated().map { offset, key in
            switch key {
            case let .int(i): return "[\(i)]"
            case let .string(s): return (offset > 0 ? "." : "") + s
            }
        }.joined()
    }
    
    public var description: String { string }
    
}
