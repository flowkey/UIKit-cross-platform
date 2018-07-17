# Architecture

## Overview
![overall-architecture](https://user-images.githubusercontent.com/10008938/42819122-e147ca8e-89d2-11e8-8227-454a98963953.png)

UIKit-cross-platform is based on the following APIs for rendering and accessing other device functionatlities:
- [SDL_gpu](https://github.com/grimfang4/sdl-gpu) for graphics rendering
- [SDL2](https://www.libsdl.org/) for additional device functionalities
- [SDL_ttf](https://www.libsdl.org/projects/SDL_ttf/) for fonts rendering

Swift code is compiled:
- with [Swift Package Manager](https://github.com/apple/swift-package-manager) for Android
- with [Xcode](https://developer.apple.com/xcode/) for Mac

On Android the compiled Swift Code is called through the [JNI (Java Native Interface)](https://docs.oracle.com/javase/7/docs/technotes/guides/jni/spec/jniTOC.html) similar to C/C++ Code with the [NDK](https://developer.android.com/ndk/).

## Rendering

![rendering-details](https://user-images.githubusercontent.com/10008938/27796338-f6831442-6009-11e7-8ec8-fa5e092136fe.png)