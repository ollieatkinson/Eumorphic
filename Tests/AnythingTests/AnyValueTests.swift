import XCTest
import Combine

@testable import Anything

final class EumorphicTests: XCTestCase {
    
    func test_bidirectional_index() throws {
        
        let empty = [Any]()
        XCTAssertEqual(empty.bidirectionalIndex(4), 4)
        XCTAssertEqual(empty.bidirectionalIndex(10), 10)
        XCTAssertEqual(empty.bidirectionalIndex(11), 11)
        XCTAssertEqual(empty.bidirectionalIndex(-1), 0)
        
        let array1 = Array(0...5) as [Any]
        XCTAssertEqual(array1.count, 6)
        XCTAssertEqual(array1.bidirectionalIndex(5), 5)
        XCTAssertEqual(array1.bidirectionalIndex(-1), 5)
        
        let array2 = Array(0...10) as [Any]
        XCTAssertEqual(array2.count, 11)
        XCTAssertEqual(array2.bidirectionalIndex(4), 4)
        XCTAssertEqual(array2.bidirectionalIndex(9), 9)
        XCTAssertEqual(array2.bidirectionalIndex(10), 10)
    }
    
    func test_get_set() throws {
        
        var dictionary: [String: Any] = [
            "string": "hello world",
            "int": 1,
            "structure": [
                "is": [
                    "good": [
                        true,
                        [
                            "and": [
                                "i": [
                                    "like": [
                                        "pie",
                                        "programming",
                                        "dogs"
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        XCTAssert(dictionary["string" as AnyPath] == "hello world")
        XCTAssert(dictionary["int" as AnyPath] == 1)

        XCTAssert(dictionary["structure", "is", "good", 0] == true)
        XCTAssert(dictionary["structure.is.good[0]" as AnyPath] == true)
        XCTAssert(dictionary[path: "structure.is.good[0]"] == true)

        XCTAssertNil(dictionary["structure", "is", "good", 1, "and", "i", "like", 3])
        
        dictionary["structure", "is", "good", 5, "and", "i", "like", 3] = [ "noodles", "chicken" ]
        
        XCTAssert(dictionary["structure", "is", "good", 5, "and", "i", "like", 3] == ["noodles", "chicken"])
        XCTAssert(dictionary[path: "structure.is.good[5].and.i.like[3]"] == ["noodles", "chicken"])
    }
    
    func test_codable() throws {
        
        struct A: Codable, Equatable {
            let bool: Bool
            let int: Int?
            let string: String
            let date: Date
            let url: URL
            let deeply: Deep
            let ints: [Int?]
            let nested: [Deep.Nested]
            let optionalNested: [Deep.Nested?]
            let keyedNested: [String: Deep.Nested]
            let keyedOptionalNested: [String: Deep.Nested?]
            let nilInt: Int?
            
            struct Deep: Codable, Equatable {
                
                let nested: Nested?
                
                struct Nested: Codable, Equatable {
                    let bool: Bool
                    let int: Int
                    let string: String?
                    let date: Date?
                    let urls: [URL]
                }
            }
        }
        
        let url = URL(string: "https://example.com")!
        
        let nested = A.Deep.Nested(
            bool: false,
            int: 1,
            string: "first",
            date: nil,
            urls: [url, url]
        )
        
        let value = A(
            bool: true,
            int: nil,
            string: "📀!",
            date: Date.distantPast,
            url: url,
            deeply: .init(nested: nested),
            ints: [nil, 1, 2, 3],
            nested: [nested, nested],
            optionalNested: [nested, nil, nested],
            keyedNested: ["first": nested],
            keyedOptionalNested: ["first": nil, "second": nested],
            nilInt: 3
        )

        assertCoding(value)
        assertCoding(Optional.some(value))
        assertCoding([value, value])
        assertCoding(["1": value, "2": value])
    }
}

func assertCoding<T: Codable & Equatable>(_ value: T, _ file: StaticString = #file, _ line: UInt = #line) {
    do {
        let encoded = try AnyEncoder().encode(value)
        let decoded = try AnyDecoder().decode(T.self, from: encoded)
        XCTAssertEqual(value, decoded, file: file, line: line)
    } catch {
        XCTFail("\(error)", file: file, line: line)
    }
}

func assertNoThrow<T>(_ expression: @autoclosure () throws -> T, file: StaticString = #filePath, line: UInt = #line) -> T? {
    do {
        return try expression()
    } catch {
        XCTFail("\(error)", file: file, line: line)
        return nil
    }
}

extension Optional {
    public func unwrap(
        _ file: StaticString = #filePath,
        _ line: UInt = #line
    ) throws -> Wrapped {
        try XCTUnwrap(self, file: file, line: line)
    }
}
