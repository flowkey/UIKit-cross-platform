//
//  setAndroidMain.swift
//  UIKit
//
//  Created by Chris on 10.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

#if os(Android)
import SDL
import CJNI

private var androidMain: (() -> Void)?

public func setAndroidMain(_ main: (() -> Void)?) {
    androidMain = main
}

@_silgen_name("SDL_Android_Init")
public func SDLAndroidInit(_ env: UnsafeMutablePointer<JNIEnv>, _ cls: JavaClass)

@_silgen_name("Java_org_libsdl_app_SDLActivity_nativeInit")
public func nativeInit(env: UnsafeMutablePointer<JNIEnv>, cls: JavaClass, array: JavaObject) -> JavaInt {
    SDLAndroidInit(env, cls)
    SDL_SetMainReady()

    guard let androidMain = androidMain else {
        fatalError("No main function for Android set: Call setAndroidMain in JNI_OnLoad to set it")
    }

    androidMain()

    return 0
}
#endif

