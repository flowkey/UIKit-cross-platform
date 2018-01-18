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

@_silgen_name("SDL_Android_Init")
public func SDLAndroidInit(_ env: UnsafeMutablePointer<JNIEnv>, _ view: JavaObject)

@_silgen_name("Java_org_libsdl_app_SDLActivity_nativeInit")
public func nativeInit(env: UnsafeMutablePointer<JNIEnv>, view: JavaObject) -> JavaInt {
    SDLAndroidInit(env, view)
    SDL_SetMainReady()
    SDL.initialize()
    return 0
}
#endif

