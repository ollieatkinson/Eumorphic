// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Eumorphic",
    platforms: [.macOS(.v10_14), .iOS(.v12)],
    products: [
        .library(name: "Eumorphic", targets: ["Eumorphic"]),
    ],
    targets: [
        .target(name: "Eumorphic", dependencies: []),
        .testTarget(name: "EumorphicTests", dependencies: ["Eumorphic"])
    ]
)
