// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "UIKit",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "UIKit", targets: ["UIKit"])
    ],
    dependencies: [
        .package(path: "./swift-jni"),
        .package(path: "./SDL"),
    ],
    targets: [
        .target(
            name: "UIKit",
            dependencies: [
                .product(name: "SDL_Android", package: "SDL", condition: .when(platforms: [.android])),
                .product(name: "JNI", package: "swift-jni", condition: .when(platforms: [.android])),
                .target(name: "UIKit_C_API", condition: .when(platforms: [.android])),
            ],
            path: "Sources",
            exclude: [
                "Mac-Info.plist",
            ]
        ),
        .target(
            name: "UIKit_C_API",
            path: "UIKit_C_API"
        ),
    ]
)
