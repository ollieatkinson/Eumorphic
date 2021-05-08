import Heterogeneous

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

dictionary[at: "structure", "is", "good", 0] // true
dictionary[at: "structure", "is", "good", 1, "and", "i", "like", 3] // nil

dictionary[at: "structure", "is", "good", 5, "and", "i", "like", 3] = [ "noodles", "chicken" ]
dictionary[at: "structure", "is", "good", 5, "and", "i", "like", 3] // ["noodles", "chicken"]

dictionary
