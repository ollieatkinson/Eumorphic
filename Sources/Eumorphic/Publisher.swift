//
//  Publisher.swift
//  
//
//  Created by Oliver Atkinson on 08/05/2021.
//

#if canImport(Combine)

import Combine

@available(macOS 10.15, iOS 13, *)
extension Publisher where Output: Eumorphic {
        
    public subscript<T>(at crumbs: Path.Crumb..., as type: T.Type = T.self) -> AnyPublisher<T, Failure> where T: Equatable {
        self[at: Path(crumbs), as: T.self]
    }
    
    public subscript<T>(at path: Path, as type: T.Type = T.self) -> AnyPublisher<T, Failure> where T: Equatable {
        self[at: path].as(T.self).scanNew().eraseToAnyPublisher()
    }
}

@available(macOS 10.15, iOS 13, *)
extension Publisher where Output == AnyEumorphic {
    
    public subscript(at crumbs: Path.Crumb...) -> Publishers.CompactMap<Self, Any> {
        self[at: Path(crumbs)]
    }
    
    public subscript(at path: Path) -> Publishers.CompactMap<Self, Any> {
        compactMap{ $0[at: path] }
    }
}

@available(macOS 10.15, iOS 13, *)
extension Publisher {
    
    public subscript(at crumbs: Path.Crumb...) -> Publishers.CompactMap<Self, Any> {
        self[at: Path(crumbs)]
    }
    
    public subscript(at path: Path) -> Publishers.CompactMap<Self, Any> {
        compactMap{ AnyEumorphic($0)[at: path] }
    }
    
    public func `as`<T>(_: T.Type = T.self) -> Publishers.CompactMap<Self, T> {
        compactMap { $0 as? T }
    }
}

@available(macOS 10.15, iOS 13, *)
extension Publisher where Output: Equatable {
    
    public func scanNew() -> AnyPublisher<Output, Failure> {
        scan((nil, nil), { ($1, $0.0) })
            .compactMap{ old, new -> (newValue: Output, oldValue: Output)? in
                guard let a = old else { return nil }
                guard let b = new else { return (a, a) }
                guard a != b else { return nil }
                return (a, b)
            }
            .map(\.newValue)
            .eraseToAnyPublisher()
    }
}

#endif
