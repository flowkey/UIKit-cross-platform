// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "UIKit",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "UIKit", targets: ["UIKit"]),
        // In-process UI-test framework (XCUIApplication/XCUIElement + XCTest-style asserts), named
        // `XCTest` so tests `import XCTest` on every platform. A separate target/product so it is
        // never linked into the shipping UIKit library.
        .library(name: "UIKitTest", targets: ["UIKitTest"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftAndroid/swift-jni", from: "3.0.0"),
        .package(path: "./SDL"),
    ],
    targets: [
        .target(
            name: "UIKit",
            dependencies: [
                .product(name: "SDL", package: "SDL"),
                .product(name: "JNI", package: "swift-jni", condition: .when(platforms: [.android])),
                .target(name: "UIKit_C_API", condition: .when(platforms: [.android])),
            ],
            path: "Sources",
            exclude: ["Mac-Info.plist"],
            swiftSettings: [.interoperabilityMode(.Cxx, .when(platforms: [.android]))]
        ),
        .target(name: "UIKit_C_API", path: "UIKit_C_API"),
        .target(
            name: "UIKitTest",
            dependencies: ["UIKit"],
            path: "UIKitTest",
            swiftSettings: [.interoperabilityMode(.Cxx, .when(platforms: [.android]))]
        ),
    ],
    swiftLanguageModes: [.v5]
)
