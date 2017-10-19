// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "UIKit",
    products: [
        .library(name: "UIKit", type: .dynamic, targets: ["UIKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/flowkey/SDL2-SwiftPackageManager.git", from: "2.0.0"),
        .package(url: "https://github.com/SwiftAndroid/swift-jni.git", from: "1.2.0")
    ],
    targets: [
        .target(name: "UIKit", dependencies: ["JNI"], path: "Sources", exclude: [
            "VideoPlayer+Mac.swift",
            "AVPlayerLayer+Mac.swift"
        ]),
    ]
)
