# UIKit-cross-platform

[![CircleCI](https://circleci.com/gh/flowkey/UIKit-cross-platform.svg?style=shield&circle-token=2bc60653f4bb369754b04d97d324d9ba2bee6c6b)](https://circleci.com/gh/flowkey/UIKit-SDL)
[![Swift4.1](https://img.shields.io/badge/swift-4.1-orange.svg?style=flat)](https://swift.org/)
[![Platforms](https://img.shields.io/badge/platform-Android%20%7C%20macOS-lightgrey.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/license-MIT-71787A.svg)](https://tldrlegal.com/license/mit-license)

UIKit-crossplatform is a **UI framework** for native apps, which enables **code targeting iOS UIKit** to run on other platforms, particularly on **Android**.<br>

## Architecture

UIKit-crossplatform is based on [SDL_GPU](https://github.com/grimfang4/sdl-gpu) which uses [OpenGL](https://www.opengl.org/) underneath to render directly to the GPU.
On Android [Swift Package Manager](https://github.com/apple/swift-package-manager) compiles Swift Code into native binaries, which are called through the [NDK](https://developer.android.com/ndk/).

![image](https://user-images.githubusercontent.com/10008938/42819122-e147ca8e-89d2-11e8-8227-454a98963953.png)

[ARCHITECTURE.md](docs/ARCHITECTURE.md) provides more detailed information about the architecture.

## Quick start

1. Setup the [UIKit-cross-platform-cli](https://github.com/flowkey/UIKit-cross-platform-cli)
2. Prepare your iOS Project
    1. Remove storyboards
    2. Adjust your [AppDelegate.swift](#Existing-AppDelegate.swift)
    3. Create a [main.swift](#New-main.swift)
3. Run `uikit-cross-platform create` and follow the steps
4. Open `android` folder in Android Studio and press "run" button

## Setup details

### File modifications

#### Existing `AppDelegate.swift`:
- Remove `@UIApplicationMain` attribute and make the class `final`
```
//@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    ...
```
- Initialize `UIWindow` and `ViewController` in `application` function
```
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow()
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()

        return true
    }
```

#### New `main.swift`:
```
import UIKit
import Foundation

UIApplicationMain(0, nil, nil, NSStringFromClass(AppDelegate.self))
```

## API documentation

This framework uses the [Apple UIKit](https://developer.apple.com/documentation/uikit) API, therefore the official Apple Docs serve as documentation for the already implemented features.

## Feature Coverage

This framework currently covers ~40% of the Apple UIKit API.

[FEATURE_COVERAGE.md](docs/FEATURE_COVERAGE.md) provides more details about which features are currently covered and how to request new features.

## How to contribute

Contributions are *very welcome* and *helpful* 🙌

If you are looking for a feature or find a bug, please create an [issue](https://github.com/flowkey/UIKit-cross-platform/issues/new/choose).

For additional information please refer to our [contribution guidelines](docs/CONTRIBUTING.md).

## FAQs / Troubleshooting

*TBD*

## License

UIKit-cross-platform is free software; you can redistribute it and/or modify it under the terms of the MIT License.
