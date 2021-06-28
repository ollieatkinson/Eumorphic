// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Anything",
    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
        .library(name: "Anything", targets: ["Anything"]),
    ],
    targets: [
        .target(name: "Anything", dependencies: []),
        .testTarget(name: "AnythingTests", dependencies: ["Anything"])
    ]
)
