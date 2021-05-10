//
//  String.swift
//  
//
//  Created by Oliver Atkinson on 08/05/2021.
//

import Foundation

protocol OptionalProtocol {
    var unwrapped: Any { get }
}

func unwrap(_ any: Any) -> Any {
    (any as? OptionalProtocol)?.unwrapped ?? any
}

extension Optional: OptionalProtocol {
    
    var unwrapped: Any {
        switch self {
        case .none: return self as Any
        case let .some(wrapped): return (wrapped as? OptionalProtocol)?.unwrapped ?? wrapped
        }
    }
    
    func or(throw error: @autoclosure () -> Error) throws -> Wrapped {
        guard let wrapped = self else { throw error() }
        return wrapped
    }
}

extension String {
    
    func error(
        _ function: String = #function,
        _ file: String = #file,
        _ line: Int = #line
    ) -> Error {
        .init(message: self, function: function, file: file, line: line)
    }
    
    struct Error: Swift.Error, CustomStringConvertible, CustomDebugStringConvertible {
        
        let message: String
        let function: String
        let file: String
        let line: Int
        
        var description: String { message }
        var debugDescription: String { "\(message) ← \(file)#\(line)" }
    }
}
