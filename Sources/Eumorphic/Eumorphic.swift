//
//  Eumorphic.swift
//
//
//  Created by Oliver Atkinson on 08/05/2021.
//

import Foundation

public protocol Eumorphic {
    func get(_ path: Path) throws -> Any?
    mutating func set(_ value: Any, at path: Path) throws
}

extension Eumorphic {
    
    public subscript(at crumbs: Path.Crumb...) -> Any? {
        get { self[at: Path(crumbs), as: Any.self] }
        set { self[at: Path(crumbs), as: Any.self] = newValue }
    }
    
    public subscript(at path: Path) -> Any? {
        get { self[at: path, as: Any.self] }
        set { self[at: path, as: Any.self] = newValue }
    }
    
    public subscript<T>(at crumbs: Path.Crumb..., as type: T.Type = T.self) -> T? {
        get { try? get(Path(crumbs)) as? T }
        set { try? set(newValue as Any, at: Path(crumbs)) }
    }
    
    public subscript<T>(at path: Path, as type: T.Type = T.self) -> T? {
        get { try? get(path) as? T }
        set { try? set(newValue as Any, at: path) }
    }
}

public struct AnyEumorphic: Eumorphic {
    
    public static var empty: AnyEumorphic = .null
    public static var null: AnyEumorphic = .init(nil)

    var wrapped: Any
    
    public init(_ wrapped: Any? = nil) { self.wrapped = wrapped as Any }
    public func get(_ path: Path) throws -> Any? { try _get(path, from: wrapped) }
    public mutating func set(_ value: Any, at path: Path) throws { try _set(value, at: path, on: wrapped) }
}

extension Dictionary: Eumorphic where Key == String, Value == Any {
    
    public func get(_ path: Path) throws -> Value? {
        guard let (head, remaining) = path.first else { return self }
        guard let value = self[head.stringValue] else { throw "Value does not exist at \(path) in \(self)".error() }
        return try _get(remaining, from: value)
    }
    
    public mutating func set(_ value: Any, at path: Path) throws {
        guard let (head, remaining) = path.first else { return }
        switch (head.stringValue, remaining) {
        case nil: return
        case let (key, remaining):
            self[key] = try _set(value, at: remaining, on: self[key])
        }
    }
}

extension Array: Eumorphic where Element == Any {
    
    public func get(_ path: Path) throws -> Element? {
        guard let (head, remaining) = path.first else { return self }
        guard let idx = head.intValue.map(bidirectionalIndex) else { throw "Path indexing into array \(self) must be an Int - got: \(path)".error() }
        if indices.contains(idx) {
            return try _get(remaining, from: self[idx])
        } else {
            throw "Array index '\(idx)' out of bounds".error()
        }
    }
    
    public mutating func set(_ value: Element, at path: Path) throws {
        guard let (head, remaining) = path.first else { return }
        guard let idx = head.intValue.map(bidirectionalIndex) else { return }
        padded(to: idx, with: Optional<Any>.none as Any)
        switch (idx, remaining) {
        case nil: return
        case let (idx, remaining):
            self[idx] = try _set(value, at: remaining, on: self[idx]) as Any
        }
    }
    
    func bidirectionalIndex(_ idx: Int) -> Int {
        guard idx < 0 else { return idx }
        precondition(!isEmpty, "cannot calculate bidirectional index for an empty collection")
        return (count + idx) % count
    }
}

extension RangeReplaceableCollection where Self: BidirectionalCollection {
    
    fileprivate mutating func padded(to size: Int, with value: @autoclosure () -> Element) {
        guard !indices.contains(index(startIndex, offsetBy: size)) else { return }
        append(contentsOf: (0..<(1 + size - count)).map { _ in value() })
    }
}

// MARK :- get/set

func get<T>(_ crumbs: Path.Crumb..., from any: Any, as _: T.Type = T.self) throws -> T? {
    try get(Path(crumbs), from: any, as: T.self)
}

func get<T>(_ path: Path, from any: Any, as _: T.Type = T.self) throws -> T? {
    guard let any: Any = try _get(path, from: any) else { return nil }
    return try (any as? T).or(throw: "\(type(of: any)) is not \(T.self)".error())
}

private func _get(_ path: Path, from any: Any) throws -> Any? {
    switch any {
    case let array as [Any]: return try array.get(path)
    case let dictionary as [String: Any]: return try dictionary.get(path)
    case let fragment where path.isEmpty: return fragment
    case let fragment: throw "Path indexing into \(fragment) of \(type(of: fragment)) not allowed".error()
    }
}

@discardableResult
func set<T>(_ value: T, at crumbs: Path.Crumb..., on any: Any?) throws -> Any? {
    try set(value, at: Path(crumbs), on: any)
}

@discardableResult
func set<T>(_ value: T, at path: Path, on any: Any?) throws -> Any? {
    try _set(value, at: path, on: any)
}

@discardableResult
private func _set(_ value: Any, at path: Path, on any: Any?) throws -> Any? {
    guard let (crumb, _) = path.first else { return value }
    switch crumb {
    case .int:
        var array = (any as? [Any]) ?? []
        try array.set(value, at: path)
        return array
    case .string:
        var dictionary = (any as? [String: Any]) ?? [:]
        try dictionary.set(value, at: path)
        return dictionary
    }
}
