[![CircleCI](https://circleci.com/gh/flowkey/UIKit-cross-platform.svg?style=shield)](https://circleci.com/gh/flowkey/UIKit-cross-platform)
[![Swift5.4](https://img.shields.io/badge/swift-5.4-orange.svg?style=flat)](https://swift.org/)
[![Platforms](https://img.shields.io/badge/platform-Android%20%7C%20macOS-lightgrey.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/license-MIT-71787A.svg)](https://tldrlegal.com/license/mit-license)
[![codecov](https://codecov.io/gh/flowkey/UIKit-cross-platform/branch/master/graph/badge.svg?token=7pkfn9WaxE)](https://codecov.io/gh/flowkey/UIKit-cross-platform)

# UIKit-cross-platform

### Your Swift UI Code on Android

UIKit-cross-platform is a **UI framework** for native apps, which enables **code targeting iOS UIKit** to run on other platforms, particularly on **Android**.<br>

## Goal

Currently in mobile development apps have to be written twice, for iOS and Android, or native performance has to be sacrificed with a cross-platform solution such as React Native.

This framework aims to combine both advantages, having **native performance** and **writing code only once** but still keeping a native look & feel.

## How to run your iOS Project on Android

1. Create new iOS Project or open an existing one
2. [Prepare your iOS Project](docs/PREPARE_IOS_PROJECT.md)
3. [Add UIKit-cross-platform to your project](#adding-uikit-cross-platform)
4. Run `./UIKit/create-android-project` from the root of your iOS project
5. Open `./android` folder in [Android Studio](https://developer.android.com/studio/) ([install Android SDKs if necessary](#android-studio-setup)) and press "run" button

## Try out the demo

This project includes a DemoApp which runs on iOS, Android and Mac.

How to run it on different platforms:

1. Clone this project, `cd` into it and run `git submodule update --init --recursive`
2. Open `./samples/getting-started/DemoApp.xcodeproj` in [Xcode](https://developer.apple.com/xcode/)
    1. Run `DemoApp` target for the **iOS App**
    2. Run `DemoAppMac` target for the **Mac App**
3. Open `./samples/getting-started/android` with [Android Studio](https://developer.android.com/studio/) ([install Android SDKs if necessary](#android-studio-setup))
4. Connect an Android device and press "Run" for the **Android App**

## Additional setup instructions

### Adding UIKit-cross-platform

`UIKit-cross-platform` has to be added as a dependency to your project including its subdependencies.

The recommended way is to use `git submodules` to add it to an `UIKit` subdirectory.
In order to do so use the following command:

```
git submodule add git@github.com:flowkey/UIKit-cross-platform.git UIKit && git submodule update --init --recursive UIKit
```

### Setup build environment

1. Install [Cmake > 3.16](https://cmake.org/download/) and [Ninja](https://github.com/ninja-build/ninja/wiki/Pre-built-Ninja-packages)

```bash
brew install cmake && brew install ninja
```

2. Install [Android Studio](https://developer.android.com/studio/)
3. Add SDKs in Android Studio
    1. Open Preferences in Android Studio
    2. Go to Appearance & Behavior -> System Settings -> Android SDK
    3. under SDK Platforms: install SDK for API Level 29
    4. under SDK Tools, install `Android SDK Build Tools`
    5. under SDK Tools, install NDK 27.1.12297006 (tick `Show Package Details` to see all available versions)
    6. Press Apply / OK to install SDKs
    7. create a symlink in `/usr/local/ndk/27.1.12297006/` pointing to the path of the NDK (`ln -vsi ~/Library/Android/sdk/ndk/27.1.12297006 /usr/local/ndk/27.1.12297006`)

## Architecture

UIKit-cross-platform renders with [SDL_gpu](https://github.com/grimfang4/sdl-gpu) which translates down to lower-level [OpenGL](https://www.opengl.org/) instructions.

On Android, [CMake](https://cmake.org/) compiles Swift Code into native binaries via [Ninja](https://ninja-build.org/), which are called through the [NDK](https://developer.android.com/ndk/).

[More detailed information about the architecture can be found here](docs/ARCHITECTURE.md)

## API documentation

This framework uses the [Apple UIKit](https://developer.apple.com/documentation/uikit) API, therefore the official Apple Docs serve as documentation for the already implemented features.

## How to contribute

Contributions are _very welcome_ and _helpful_ 🙌

If you are looking for a feature or find a bug, please create an [Issue](https://github.com/flowkey/UIKit-cross-platform/issues/new/choose).

For additional information please refer to our [contribution guidelines](docs/CONTRIBUTING.md).

## FAQs / Troubleshooting

[Our FAQs can be found here](docs/FAQs.md).

## License

UIKit-cross-platform is free software; you can redistribute it and/or modify it under the terms of the [MIT License](LICENSE).
