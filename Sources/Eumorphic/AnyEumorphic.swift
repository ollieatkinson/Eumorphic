//
//  AnyEumorphic.swift
//  
//
//  Created by Oliver Atkinson on 08/05/2021.
//

public struct AnyEumorphic: Eumorphic {
    
    public static var empty: AnyEumorphic = .null
    public static var null: AnyEumorphic = .init(nil)
    
    public var wrapped: Any
    
    public init(_ wrapped: Any? = nil) { self.wrapped = wrapped as Any }
    public func get(_ path: Path) throws -> Any? { try _get(path, from: wrapped) }
    public mutating func set(_ value: Any, at path: Path) throws {
        if path.isEmpty { wrapped = value }
        else { try _set(value, at: path, on: wrapped) }
    }
}

extension AnyEumorphic: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension AnyEumorphic: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Any...) {
        self.init(elements)
    }
}

extension AnyEumorphic: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Any)...) {
        self.init([String: Any].init(elements, uniquingKeysWith: { $1 }))
    }
}

extension AnyEumorphic: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.init(value)
    }
}

extension AnyEumorphic: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension AnyEumorphic: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension AnyEumorphic: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self.init(value)
    }
}

extension AnyEumorphic: ExpressibleByStringInterpolation {
    public init(stringInterpolation: DefaultStringInterpolation) {
        self.init(stringInterpolation.description)
    }
}
