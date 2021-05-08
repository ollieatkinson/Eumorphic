# Eumorphic

[Sugar for type preserving heterogeneous containers for Swift]

--- 

`Any`,  `[Any]` and `[String: Any]` are type-erased values which allow for the storage of heterogeneous data structures.
Typically these erased structures are difficult to work with and are seen quite a lot with code that utilises `JSONSerialization`. 
Eumorphic aims to ease the burden of use by providing a light sugar over these erased types.

Offered in the package are the following features:

1. Path get/set for deeply nested data
2. Publisher for Path
3. Path is Collection, String, Codable and Hashable
4. AnyEumorphic for wrapping the original data structure or creating entirely new ones

---

## Example

```swift
import Eumorphic
import Combine

let test = Test(); class Test {
    
    var bools: [Bool] = []
    @Published var dictionary: [String: Any] = [
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
}

test.dictionary[at: "string"] // "hello world"
test.dictionary[at: "string"] = "hello swift" // "hello swift"

test.dictionary[at: "string"] == "hello swift" // true

test.dictionary[at: "structure", "is", "good", 0] // true
test.dictionary[at: "structure", "is", "good", 0, as: Bool.self] // true
test.dictionary[at: "structure", "is", "good", 0] == "no" // false
test.dictionary[at: "structure.is.good[0]"] // true

test.dictionary[at: "structure", "is", "good", 1, "and", "i", "like", 3] // nil
test.dictionary[at: "structure", "is", "good", 1, "and", "i", "like", .last] // dogs

test.dictionary[at: "structure", "is", "good", 5, "and", "i", "like", 3] = [ "noodles", "chicken" ]
test.dictionary[at: "structure", "is", "good", 5, "and", "i", "like", 3] // ["noodles", "chicken"]

var bag: Set<AnyCancellable> = []

test.$dictionary[at: "structure", "is", "good", 0]
    .collect(3)
    .assign(to: \.bools, on: test)
    .store(in: &bag)

test.dictionary[at: "structure", "is", "good", 0] = false
test.dictionary[at: "structure", "is", "good", 0] = true

test.bools // [true, false, true]

```
