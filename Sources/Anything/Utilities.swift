//
//  Created by Oliver Atkinson
//

import Foundation

public protocol FlattenOptional {
    static var null: FlattenOptional { get }
    var flattened: Any? { get }
}

public func flattenOptionality(_ any: Any) -> Any {
    (any as? FlattenOptional)?.flattened ?? any
}

public func isNil(_ any: Any?) -> Bool {
    switch any.flattened {
    case .none: return true
    case .some: return false
    }
}

extension Optional: FlattenOptional {
    
    public static var null: FlattenOptional { return Optional.none as FlattenOptional }
    
    public var flattened: Any? {
        switch self {
        case .none: return self as Any
        case let .some(wrapped): return (wrapped as? FlattenOptional)?.flattened ?? wrapped
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
        
        public var description: String { message }
        public var debugDescription: String { "\(message) ← \(file)#\(line)" }
    }
}
