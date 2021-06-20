// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "AnyValue",
    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
        .library(name: "AnyValue", targets: ["AnyValue"]),
    ],
    targets: [
        .target(name: "AnyValue", dependencies: []),
        .testTarget(name: "AnyValueTests", dependencies: ["AnyValue"])
    ]
)
