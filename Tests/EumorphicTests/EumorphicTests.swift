import XCTest
import Combine

@testable import Eumorphic

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
        
        XCTAssert(dictionary["string" as Path] == "hello world")
        XCTAssert(dictionary["int" as Path] == 1)

        XCTAssert(dictionary["structure", "is", "good", 0] == true)
        XCTAssert(dictionary["structure.is.good[0]" as Path] == true)
        XCTAssert(dictionary[path: "structure.is.good[0]"] == true)

        XCTAssertNil(dictionary["structure", "is", "good", 1, "and", "i", "like", 3])
        
        dictionary["structure", "is", "good", 5, "and", "i", "like", 3] = [ "noodles", "chicken" ]
        
        XCTAssert(dictionary["structure", "is", "good", 5, "and", "i", "like", 3] == ["noodles", "chicken"])
        XCTAssert(dictionary[path: "structure.is.good[5].and.i.like[3]"] == ["noodles", "chicken"])
    }
    
    func test_any_value() throws {
        
        var value: AnyValue = [
            "nested": [
                "value": [true, false]
            ]
        ]
        
        var bag: Set<AnyCancellable> = []
        let promise = expectation(description: "\(#line)@\(#function)")
        promise.expectedFulfillmentCount = 3
        
        value.subscribe(to: "nested", "value", 0).sink { result in
            switch result {
            case let .success(value): promise.fulfill(); print(value)
            default: XCTFail()
            }
        }.store(in: &bag)
        
        value["nested", "value", 0] = false
        value["nested", "value", 0] = true
        
        waitForExpectations(timeout: 1)
        
    }
}
