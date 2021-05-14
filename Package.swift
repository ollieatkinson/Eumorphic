// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Eumorphic",
    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
        .library(name: "Eumorphic", targets: ["Eumorphic"]),
    ],
    targets: [
        .target(name: "Eumorphic", dependencies: []),
        .testTarget(name: "EumorphicTests", dependencies: ["Eumorphic"])
    ]
)
