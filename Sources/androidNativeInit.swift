//
//  androidNativeInit.swift
//  UIKit
//
//  Created by Chris on 10.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL
import CJNI

public struct UIKitAndroid {
    public static var UIApplicationClass: UIApplication.Type?
    public static var UIApplicationDelegateClass: UIApplicationDelegate.Type?
}

@_silgen_name("SDL_Android_Init")
public func SDL_Android_Init(_ env: UnsafeMutablePointer<JNIEnv>, _ view: JavaObject)

@_cdecl("Java_org_libsdl_app_SDLActivity_nativeInit")
public func nativeInit(env: UnsafeMutablePointer<JNIEnv>, view: JavaObject) -> JavaInt {
    SDL_Android_Init(env, view)
    SDL_SetMainReady()

    if UIApplication.shared != nil {
        return 0 // already inited
    }

    return JavaInt(
        UIApplicationMain(UIKitAndroid.UIApplicationClass, UIKitAndroid.UIApplicationDelegateClass)
    )
}

@_cdecl("Java_org_libsdl_app_SDLActivity_nativeDestroyScreen")
public func nativeDestroyScreen(env: UnsafeMutablePointer<JNIEnv>, view: JavaObject) {
    UIApplication.onWillEnterBackground()
    UIApplication.onDidEnterBackground()
}
