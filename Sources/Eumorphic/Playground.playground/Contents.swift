import Eumorphic

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

dictionary["string"] // "hello world"
dictionary["string"] = "hello swift" // "hello swift"

dictionary["string" as Path] == "hello swift" // true
dictionary[path: "string"] == "hello swift" // true

dictionary["structure", "is", "good", 0] // true
dictionary["structure", "is", "good", 0, as: Bool.self] // true
dictionary["structure", "is", "good", 0] == "no" // false
dictionary["structure.is.good[0]" as Path] // true

dictionary["structure", "is", "good", 1, "and", "i", "like", 3] // nil
dictionary["structure", "is", "good", 1, "and", "i", "like", .last] // dogs

dictionary["structure", "is", "good", 5, "and", "i", "like", 3] = [ "noodles", "chicken" ]
dictionary["structure", "is", "good", 5, "and", "i", "like", 3] // ["noodles", "chicken"]

dictionary["structure", "is", "good", .first] = false
dictionary["structure", "is", "good", .first] = true

dictionary[path: "structure"] = true
dictionary[path: "structure"] // true
