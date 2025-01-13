// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "GettingStarted",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "GettingStarted", type: .dynamic, targets: ["GettingStarted"]),
    ],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .target(
            name: "GettingStarted",
            dependencies: [
                .product(name: "UIKit", package: "UIKit"),
            ],
            path: "DemoApp",
            exclude: [
                "Info.plist",
                "Base.lproj",
                "main.swift"
            ]
        )
    ]
)
