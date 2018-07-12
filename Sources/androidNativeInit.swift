//
//  androidNativeInit.swift
//  UIKit
//
//  Created by Chris on 10.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL
import CJNI

@_silgen_name("SDL_Android_Init")
public func SDLAndroidInit(_ env: UnsafeMutablePointer<JNIEnv>, _ view: JavaObject)

public var uiApplicationClass: UIApplication.Type?
public var uiApplicationDelegateClass: UIApplicationDelegate.Type?

@_silgen_name("Java_org_libsdl_app_SDLActivity_nativeInit")
public func nativeInit(env: UnsafeMutablePointer<JNIEnv>, view: JavaObject) -> JavaInt {
    SDLAndroidInit(env, view)
    SDL_SetMainReady()

    if UIApplication.shared != nil {
        return 0 // already inited
    }

    return JavaInt(UIApplicationMain(uiApplicationClass, uiApplicationDelegateClass))
}

@_silgen_name("Java_org_libsdl_app_SDLActivity_nativeDeinit")
public func nativeDeinit(env: UnsafeMutablePointer<JNIEnv>, view: JavaObject) {
    UIApplication.shared = nil
}
