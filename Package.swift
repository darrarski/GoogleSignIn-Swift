// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "GoogleSignIn",
    products: [
        .library(name: "GoogleSignIn", targets: ["GoogleSignIn"])
    ],
    dependencies: [],
    targets: [
        .target(name: "GoogleSignIn", dependencies: []),
        .testTarget(name: "GoogleSignInTests", dependencies: ["GoogleSignIn"])
    ]
)
