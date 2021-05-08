//
//  String.swift
//  
//
//  Created by Oliver Atkinson on 08/05/2021.
//

import Foundation

extension Optional {
    
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
    
    struct Error: Swift.Error, CustomStringConvertible {
        let message: String
        let function: String
        let file: String
        let line: Int
        
        var description: String {
            """
            \(message) ← ‼️ \(file)#\(line)
            """
        }
    }
}
