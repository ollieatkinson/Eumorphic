//
//  Eumorphic.swift
//
//
//  Created by Oliver Atkinson on 08/05/2021.
//

import Foundation

public protocol Eumorphic {
    func get(_ path: Path) throws -> Any
    mutating func set(_ value: Any, at path: Path) throws
}

extension Eumorphic {
    
    public subscript(_ first: Path.Crumb, _ rest: Path.Crumb...) -> Any? {
        get { self[Path([first] + rest), as: Any.self] }
        set { self[Path([first] + rest), as: Any.self] = newValue }
    }
    
    public subscript(path path: Path) -> Any? {
        get { self[path] }
        set { self[path] = newValue }
    }
    
    public subscript() -> Any? {
        get { self[Path()] }
        set { self[Path()] = newValue }
    }
    
    public subscript(path: Path) -> Any? {
        get { self[path, as: Any.self] }
        set { self[path, as: Any.self] = newValue }
    }
    
    public subscript<T>(_ first: Path.Crumb, _ rest: Path.Crumb..., as type: T.Type = T.self) -> T? {
        get { try? get(Path([first] + rest)) as? T }
        set { try? set(newValue as Any, at: Path([first] + rest)) }
    }
    
    public subscript<T>(path path: Path, as type: T.Type = T.self) -> T? {
        get { self[path, as: T.self] }
        set { self[path, as: T.self] = newValue }
    }
    
    public subscript<T>(as type: T.Type = T.self) -> T? {
        get { self[Path()] }
        set { self[Path()] = newValue }
    }
    
    public subscript<T>(path: Path, as type: T.Type = T.self) -> T? {
        get { try? get(path) as? T }
        set { try? set(newValue as Any, at: path) }
    }
}

extension Dictionary: Eumorphic where Key == String, Value == Any {
    
    public func get(_ path: Path) throws -> Value {
        guard let (head, remaining) = path.first else { return self }
        guard let value = self[head.stringValue] else { throw "\(path) → Key \(head.stringValue) does not exist at \(self)".error() }
        return try _get(remaining, from: value)
    }
    
    public mutating func set(_ value: Any, at path: Path) throws {
        guard let (head, remaining) = path.first else { return }
        switch (head.stringValue, remaining) {
        case nil: return
        case let (key, remaining):
            self[key] = try _set(value, at: remaining, on: self[key] as Any)
        }
    }
}

extension Array: Eumorphic where Element == Any {
    
    public func get(_ path: Path) throws -> Element {
        guard let (head, remaining) = path.first else { return self }
        guard let idx = head.intValue.map(bidirectionalIndex) else { throw "\(path) → Path indexing into array \(self) must be an Int - got: \(head.stringValue)".error() }
        guard indices.contains(idx) else { throw "\(path) → Array index '\(idx)' out of bounds".error() }
        return try _get(remaining, from: self[idx])
    }
    
    public mutating func set(_ value: Element, at path: Path) throws {
        guard let (head, remaining) = path.first else { return }
        guard let idx = head.intValue.map(bidirectionalIndex) else { return }
        padded(to: idx, with: Optional<Any>.none as Any)
        switch (idx, remaining) {
        case nil: return
        case let (idx, remaining):
            self[idx] = try _set(value, at: remaining, on: self[idx])
        }
    }
    
    func bidirectionalIndex(_ idx: Int) -> Int {
        guard idx < 0 else { return idx }
        guard !isEmpty else { return 0 }
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

@_spi(Eumorphic)
public func get<T>(_ path: Path, from any: Any, as _: T.Type = T.self) throws -> T? {
    let any: Any = try _get(path, from: any)
    return try (any as? T).or(throw: "\(type(of: any)) is not \(T.self)".error())
}

@_spi(Eumorphic)
public func _get(_ path: Path, from any: Any) throws -> Any {
    switch any {
    case let eumorphic as Eumorphic: return try eumorphic.get(path)
    case let array as [Any]: return try array.get(path)
    case let dictionary as [String: Any]: return try dictionary.get(path)
    case let fragment where path.isEmpty: return fragment as Any
    case let fragment: throw "\(path) → Path indexing into \(fragment) of \(type(of: fragment)) not allowed".error()
    }
}

@_spi(Eumorphic)
public func set<T>(_ value: T, at path: Path, on any: Any) throws -> Any {
    try _set(value, at: path, on: any)
}

@_spi(Eumorphic)
public func _set(_ value: Any, at path: Path, on any: Any) throws -> Any {
    guard let (crumb, _) = path.first else { return flattenOptionality(value) }
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
