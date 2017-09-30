// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CVServiceRegistry",
    products: [
        .library(name: "CVServiceRegistry", targets: ["CVServiceRegistry"]),
    ],
    dependencies: [
        .package(url: "https://github.com/cpageler93/ConsulSwift.git", from: "0.2.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "2.2.2")
    ],
    targets: [
        .target(name: "CVServiceRegistry", dependencies: [
            .byNameItem(name: "ConsulSwift"),
            .byNameItem(name: "Vapor")
        ]),
        .testTarget(name: "CVServiceRegistryTests", dependencies: ["CVServiceRegistry"]),
    ]
)
