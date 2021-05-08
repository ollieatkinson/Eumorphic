//
//  Path.swift
//  
//
//  Created by Oliver Atkinson on 08/05/2021.
//

import Foundation

prefix operator ^ // Lift operator to convert Int or String to Path.Crumb

public struct Path: Collection {
    
    public enum Crumb {
        case int(Int)
        case string(String)
    }
    
    public typealias Base = AnyRandomAccessCollection<Crumb>
    public typealias Index = Base.Index
    
    let base: Base
    
    public init<C>(_ base: C) where C: RandomAccessCollection, C.Element == Crumb {
        self.base = AnyRandomAccessCollection(base)
    }
}

extension Path: ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: Crumb...) {
        self.init(elements)
    }
}

extension Path {
    
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
    public subscript(position: Base.Index) -> (head: Crumb, tail: Path) {
        return (base[position], Path(base.suffix(from: index(after: position))))
    }
}

extension Path {
    public var crumb: AnyRandomAccessCollection<Crumb> { base }
}

extension Path: BidirectionalCollection {
    
    public func index(before i: Base.Index) -> Base.Index {
        base.index(before: i)
    }
}

extension Path: RandomAccessCollection {}
extension Path: LazySequenceProtocol {}
extension Path: LazyCollectionProtocol {}
extension Path: Equatable {
    
    public static func == (lhs: Path, rhs: Path) -> Bool {
        lhs.base.elementsEqual(rhs.base)
    }
}
extension Path: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        for o in base {
            hasher.combine(o)
        }
    }
}

extension Path: Codable {
    
    public init(from decoder: Decoder) throws {
        let string = try String(from: decoder)
        self = try Self.init(string).or(throw: "Could not create path from \(string)".error())
    }
    
    public func encode(to encoder: Encoder) throws {
        try string.encode(to: encoder)
    }
}

extension Path.Crumb {
    public static var last: Self { ^(-1) }
}

extension Path.Crumb {
    static func string(_ string: Substring) -> Self {
        .string(string.string)
    }
}

extension Path.Crumb: CodingKey, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
    
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

extension Path.Crumb: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .int(i): hasher.combine(i)
        case let .string(s): hasher.combine(s)
        }
    }
    
    public static func == (lhs: Path.Crumb, rhs: Path.Crumb) -> Bool {
        switch (lhs, rhs) {
        case let (.int(i), .int(j)): return i == j
        case let (.string(i), .string(j)): return i == j
        default: return false
        }
    }
    
}

public prefix func ^ (r: Int) -> Path.Crumb { .int(r) }
public prefix func ^ <S>(r: S) -> Path.Crumb where S: StringProtocol { .string(r.string) }

extension Path.Crumb: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .int(let o): return o.description
        case .string(let o): return o
        }
    }
}

extension Path.Crumb {
    
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

extension Path.Crumb {
    
    public init(_ string: String) {
        self = .string(string)
    }
    
    public init(_ int: Int) {
        self = .int(int)
    }
}

extension Path.Crumb: Codable {
    
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

extension Path: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.init(value)!
    }
}

extension Path: LosslessStringConvertible {
    
    public static let pattern = try! NSRegularExpression(pattern: #"\.?((?<name>[\w]+)|\[(?<idx>[\d]+)\])"#)
    
    public init?(_ description: String) {
        do {
            self = try Self(Path.pattern.matches(in: description, range: NSRange(description.startIndex..<description.endIndex, in: description)).map { match in
                
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
