//
//  AnyValue.swift
//  
//
//  Created by Oliver Atkinson on 14/05/2021.
//

import Combine

public struct AnyValue: Eumorphic {
    
    public static var empty: AnyValue = .null
    public static var null: AnyValue = .init(nil)
    
    public var wrapped: Any {
        didSet { subject.send(wrapped) }
    }
    
    public init(_ value: Any? = nil) {
        wrapped = value.flattened as Any
    }
    
    public func get(_ path: Path) throws -> Any {
        try _get(path, from: wrapped)
    }
    
    public mutating func set(_ value: Any, at path: Path) throws {
        guard path.isNotEmpty else { return (wrapped = value) }
        wrapped = try _set(value, at: path, on: wrapped)
    }
    
    private var subject = PassthroughSubject<Any, Never>()
}

extension AnyValue {
    
    public func subscribe(to first: Path.Crumb, _ rest: Path.Crumb...) -> AnyPublisher<Result<Any, Error>, Never> {
        subscribe(to: Path([first] + rest))
    }
    
    public func subscribe(to path: Path) -> AnyPublisher<Result<Any, Error>, Never> {
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
