# UIKit-cross-platform

[![CircleCI](https://circleci.com/gh/flowkey/UIKit-cross-platform.svg?style=shield&circle-token=2bc60653f4bb369754b04d97d324d9ba2bee6c6b)](https://circleci.com/gh/flowkey/UIKit-SDL)
[![Swift4.1](https://img.shields.io/badge/swift-4.1-orange.svg?style=flat)](https://swift.org/)
[![Platforms](https://img.shields.io/badge/platform-Android%20%7C%20macOS-lightgrey.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/license-MIT-71787A.svg)](https://tldrlegal.com/license/mit-license)

UIKit-crossplatform is a **UI framework** for native apps, which enables **code targeting iOS UIKit** to run on other platforms, particularly on **Android**.<br>

## How does it work

UIKit-cross-platform renders with [SDL_gpu](https://github.com/grimfang4/sdl-gpu) which uses [OpenGL(ES)](https://www.opengl.org/).
On Android [Swift Package Manager](https://github.com/apple/swift-package-manager) compiles Swift Code into native binaries, which are called through the [NDK](https://developer.android.com/ndk/).

![uikit-architecture](https://user-images.githubusercontent.com/10008938/42819122-e147ca8e-89d2-11e8-8227-454a98963953.png)

[ARCHITECTURE.md](docs/ARCHITECTURE.md) provides more detailed information about the architecture.

## Try it out yourself

This project includes a DemoApp which runs on iOS, Android and Mac.

To try it:
1. Clone this project and run `git submodule update --init --recursive`
2. Open `./demo/DemoApp.xcodeproj` in Xcode
    1. Run `DemoApp` target for the iOS App
    2. Run `DemoAppMac` target for the Mac App
3. Open `./demo/android` with Android Studio ([Setup if necessary]())
4. Connect an Android device and press "Run" in Android Studio

## How run an iOS Project on Android

1. Create new iOS Project or open an existing one
2. Prepare your iOS Project
    1. [Remove storyboards](#Storyboards-cleanup)
    2. Adjust your [AppDelegate.swift](#Existing-AppDelegate.swift)
    3. Create a [main.swift](#New-main.swift)
3. [Add UIKit-cross-platform to your project](#adding-UIKit-cross-platform)
4. Run ` ./UIKit/cli create-from-ios` to create a new android project from your existing iOS project
5. Open `android` folder in Android Studio and press "run" button

## Setup details

### Storyboards cleanup

1. Delete Storyboards, in a new project the following two files: `Main.storyboard`, `LaunchScreen.storyboard`
2. Remove your deleted Storyboards from `Info.plist`
![Info.plist - deletions](https://user-images.githubusercontent.com/10008938/42874868-85e1ed68-8a82-11e8-84f8-678fe6cbf5f4.png)


### File modifications for an iOS Project

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

### Adding UIKit-cross-platform

`UIKit-cross-platform` has to be added as a dependency to your project including its subdependencies.

The recommended way is to use `git submodules` to add it to an `UIKit` subdirectory.
In order to do so use the following command:
```
git submodule add git@github.com:flowkey/UIKit-cross-platform.git UIKit && cd UIKit && git submodule update --init --recursive
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
