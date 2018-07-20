# Architecture

*WORK IN PROGRESS*

## Overview
![overall-architecture](https://user-images.githubusercontent.com/10008938/42947401-84bbd778-8b6d-11e8-992b-d0625b1fe1e9.png)

UIKit-cross-platform is based on the following APIs for rendering and accessing other device functionatlities:
- [SDL_gpu](https://github.com/grimfang4/sdl-gpu) for graphics rendering
- [SDL2](https://www.libsdl.org/) for additional device functionalities
- [SDL_ttf](https://www.libsdl.org/projects/SDL_ttf/) for fonts rendering

Swift code is compiled:
- with [Swift Package Manager](https://github.com/apple/swift-package-manager) for Android
- with [Xcode](https://developer.apple.com/xcode/) for Mac

On Android the compiled Swift Code is called through the [JNI (Java Native Interface)](https://docs.oracle.com/javase/7/docs/technotes/guides/jni/spec/jniTOC.html) similar to C/C++ Code with the [NDK](https://developer.android.com/ndk/).

## Rendering

This illustration shows with the example of a `Button` how the rendering hierarchy works based on `SDL_gpu`.

![uikit_rendering_button](https://user-images.githubusercontent.com/10008938/43000101-6a3a2522-8c20-11e8-895b-89d0c0942990.png)