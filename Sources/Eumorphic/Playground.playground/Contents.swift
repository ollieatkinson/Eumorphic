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

test.dictionary[at: []] = true
