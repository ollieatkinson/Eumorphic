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
        
    public subscript<T>(_ first: Path.Crumb, _ rest: Path.Crumb..., as type: T.Type = T.self) -> AnyPublisher<T, Failure> where T: Equatable {
        self[Path([first] + rest), as: T.self]
    }
    
    public subscript<T>(path: Path, as type: T.Type = T.self) -> AnyPublisher<T, Failure> where T: Equatable {
        self[path].as(T.self).scanNew().eraseToAnyPublisher()
    }
}

@available(macOS 10.15, iOS 13, *)
extension Publisher where Output == AnyEumorphic {
    
    public subscript(_ first: Path.Crumb, _ rest: Path.Crumb...) -> Publishers.CompactMap<Self, Any> {
        self[Path([first] + rest)]
    }
    
    public subscript(path: Path) -> Publishers.CompactMap<Self, Any> {
        compactMap{ $0[path] }
    }
}

@available(macOS 10.15, iOS 13, *)
extension Publisher {
    
    public subscript(_ first: Path.Crumb, _ rest: Path.Crumb...) -> Publishers.CompactMap<Self, Any> {
        self[Path([first] + rest)]
    }
    
    public subscript(path: Path) -> Publishers.CompactMap<Self, Any> {
        compactMap{ AnyEumorphic($0)[path] }
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
