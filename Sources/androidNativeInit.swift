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
    @_silgen_name("SDL_Android_Init")
    public static func SDL_Android_Init(_ env: UnsafeMutablePointer<JNIEnv>, _ view: JavaObject)

    public static var UIApplicationClass: UIApplication.Type?
    public static var UIApplicationDelegateClass: UIApplicationDelegate.Type?

    @_silgen_name("Java_org_libsdl_app_SDLActivity_nativeInit")
    public static func nativeInit(env: UnsafeMutablePointer<JNIEnv>, view: JavaObject) -> JavaInt {
        SDL_Android_Init(env, view)
        SDL_SetMainReady()

        if UIApplication.shared != nil {
            return 0 // already inited
        }

        return JavaInt(
            UIApplicationMain(UIApplicationClass, UIApplicationDelegateClass)
        )
    }

    @_silgen_name("Java_org_libsdl_app_SDLActivity_nativeDestroyScreen")
    public static func nativeDestroyScreen(env: UnsafeMutablePointer<JNIEnv>, view: JavaObject) {
        UIApplication.onWillEnterBackground()
        UIApplication.onDidEnterBackground()
    }
}
