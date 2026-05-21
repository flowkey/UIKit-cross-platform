// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "UIKit",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "UIKit", targets: ["UIKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftAndroid/swift-jni", branch: "devel"),
        .package(path: "./SDL"),
        .package(url: "https://github.com/michaelknoch/rlottie.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "UIKit",
            dependencies: [
                .product(name: "SDL", package: "SDL"),
                .product(name: "JNI", package: "swift-jni", condition: .when(platforms: [.android])),
                .target(name: "UIKit_C_API", condition: .when(platforms: [.android])),
                .product(name: "Crlottie", package: "Rlottie", condition: .when(platforms: [.macOS, .android])),
            ],
            path: "Sources",
            exclude: ["Mac-Info.plist"]
        ),
        .target(name: "UIKit_C_API", path: "UIKit_C_API"),
    ],
    swiftLanguageModes: [.v5]
)
