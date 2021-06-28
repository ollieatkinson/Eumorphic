struct AnyCodingKey: CodingKey {
    var stringValue: String, intValue: Int?
    init?(intValue: Int) { (self.intValue, self.stringValue) = (intValue, intValue.description) }
    init?(stringValue: String) { (self.intValue, self.stringValue) = (nil, stringValue) }
}

extension AnyCodingKey {
    init<K>(_ key: K) where K: CodingKey { (self.intValue, self.stringValue) = (key.intValue, key.stringValue) }
    init(_ int: Int) { self.init(intValue: int)! }
    init(_ string: String) { self.init(stringValue: string)! }
}

extension AnyCodingKey: ExpressibleByStringLiteral {
    init(stringLiteral value: String) { self.init(stringValue: value)! }
}

extension AnyCodingKey: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) { self.init(intValue: value)! }
}
