# UIKit-crossplatform

[![CircleCI](https://circleci.com/gh/flowkey/UIKit-SDL.svg?style=shield&circle-token=2bc60653f4bb369754b04d97d324d9ba2bee6c6b)](https://circleci.com/gh/flowkey/UIKit-SDL)
[![Swift4.1](https://img.shields.io/badge/swift-4.1-lightgrey.svg?style=flat)](https://swift.org/)
[![Platforms](https://img.shields.io/badge/platform-Android%20%7C%20macOS%20%7C%20linux-lightgrey.svg)](https://swift.org/)

UIKit-crossplatform is a **UI framework** for native apps, which enables **code targeting iOS UIKit** to run on other platforms, particularly on **Android**.<br>

## Overview

### Goals

*// to be added*

### Architecture

UIKit-crossplatform is based on [SDL_GPU](https://github.com/grimfang4/sdl-gpu) which uses [OpenGL](https://www.opengl.org/) underneath to render directly to the GPU.
On Android [Swift Package Manager](https://github.com/apple/swift-package-manager) compiles Swift Code into native binaries, which are called through the [NDK](https://developer.android.com/ndk/).

[ARCHITECTURE.md](docs/ARCHITECTURE.md) provides more detailed information about the architecture.

### API documentation

This framework uses the [Apple UIKit](https://developer.apple.com/documentation/uikit) API, therefore the official Apple Docs serve as documentation for the already implemented features.

## Getting started

*// expand on this part once first version of the tooling is ready*

## Feature Coverage

refer to FEATURE_COVERAGE.md here

## How to contribute

*refer to open issues*<br>
*refer to CONTRIBUTING.md*

## FAQs / Troubleshooting

*// add Q&A here when using the tooling to setup Android Apps*

## License

UIKit-SDL is free software; you can redistribute it and/or modify it under the terms of the MIT License.



