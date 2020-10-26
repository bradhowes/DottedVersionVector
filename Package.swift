// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DottedVersionVector",
    products: [
        .library(
            name: "DottedVersionVector",
            targets: ["DottedVersionVector"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "DottedVersionVector",
            dependencies: [],
            exclude: ["README.md"]
            ),
        .testTarget(
            name: "DottedVersionVectorTests",
            dependencies: ["DottedVersionVector"]),
    ]
)
