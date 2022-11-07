//
//  androidNativeInit.swift
//  UIKit
//
//  Created by Chris on 10.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL
import JNI

public struct UIKitAndroid {
    public static var UIApplicationDelegateClass: UIApplicationDelegate.Type?
    public static var UIApplicationClass: UIApplication.Type = UIApplication.self
}

@_silgen_name("SDL_Android_Init")
public func SDL_Android_Init(_ env: UnsafeMutablePointer<JNIEnv>, _ view: JavaObject)

@MainActor
@_cdecl("Java_org_libsdl_app_SDLActivity_nativeInit")
public func nativeInit(env: UnsafeMutablePointer<JNIEnv>, view: JavaObject) -> JavaInt {
    SDL_Android_Init(env, view)
    SDL_SetMainReady()

    if UIApplication.shared == nil {
        return JavaInt(
            UIApplicationMain(UIKitAndroid.UIApplicationClass, UIKitAndroid.UIApplicationDelegateClass)
        )
    }

    // UIApplicationMain also inits a screen, so this is a special case.
    if UIScreen.main == nil {
        UIScreen.main = UIScreen()
    }

    return 0
}

@MainActor
@_cdecl("Java_org_libsdl_app_SDLActivity_nativeDestroyScreen")
public func nativeDestroyScreen(env: UnsafeMutablePointer<JNIEnv>, view: JavaObject) {
    UIApplication.onWillEnterBackground()
    UIApplication.onDidEnterBackground()
}
