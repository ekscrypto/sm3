// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SM3",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SM3",
            targets: ["SM3"]
        ),
        .executable(
            name: "sm3-benchmark",
            targets: ["SM3Benchmark"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SM3"
        ),
        .executableTarget(
            name: "SM3Benchmark",
            dependencies: ["SM3"]
        ),
        .testTarget(
            name: "SM3Tests",
            dependencies: ["SM3"]
        ),
    ]
)
