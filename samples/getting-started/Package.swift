// swift-tools-version:4.1
import PackageDescription

let targets: [Target] = [
    .target(
        name: "DemoApp",
        dependencies: [],
        path: "DemoApp",
        exclude: ["main.swift"]
    )
]

let package = Package(
    name: "DemoApp",
    products: [
        .library(name: "DemoApp", type: .dynamic, targets: ["DemoApp"]),
    ],
    targets: targets
)
