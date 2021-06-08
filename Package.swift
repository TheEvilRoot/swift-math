// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Math",
    platforms: [
        .iOS(.v8), .macOS(.v10_10)
    ],
    products: [
        .library(
            name: "Math",
            targets: ["Math"]),
    ],
    targets: [
        .target(
            name: "Math",
            dependencies: []),
        .testTarget(
            name: "MathTests",
            dependencies: ["Math"]),
    ]
)
