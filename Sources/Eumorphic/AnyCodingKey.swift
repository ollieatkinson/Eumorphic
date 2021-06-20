struct AnyCodingKey: CodingKey {
    
    var stringValue: String
    var intValue: Int?
    
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
    init?(stringValue: String) {
        self.intValue = nil
        self.stringValue = stringValue
    }
}

extension AnyCodingKey {
    init<T: CodingKey>(_ key: T) {
        self.stringValue = key.stringValue
        self.intValue = key.intValue
    }
    init(_ int: Int) {
        self.init(intValue: int)!
    }
    init(_ string: String) {
        self.init(stringValue: string)!
    }
}

extension AnyCodingKey: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.init(stringValue: value)!
    }
}

extension AnyCodingKey: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        self.init(intValue: value)!
    }
}
