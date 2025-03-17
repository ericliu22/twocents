// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TwoCentsInternal",
    platforms: [
        .iOS(.v18)  // or the minimum version you support
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TwoCentsInternal",
            type: .static,  // <-- This line specifies a static library.
            targets: ["TwoCentsInternal"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.9.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TwoCentsInternal",
            dependencies: [
                // Specify the Firebase products you need.
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
