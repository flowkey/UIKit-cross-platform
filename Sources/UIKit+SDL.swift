//
//  UIKit.swift
//  sdl2testapinotes
//
//  Created by Geordie Jay on 11.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

import SDL
import SDL_gpu
import CoreFoundation
import JNI

final public class SDL { // Only public for rootView!
    public internal(set) static var window: UIWindow!
    public static var rootView: UIView! {
        get { return window.rootViewController!.view }
    }

    static var glRenderer: GLRenderer!

    fileprivate static var shouldQuit = false

    public static func initialize() {
        self.shouldQuit = false
        self.firstRender = true
        self.glRenderer = nil // triggers GLRenderer deinit

        self.glRenderer = GLRenderer()
        self.window = glRenderer.createKeyWindow()
        window.makeKeyAndVisible()

        UIFont.loadSystemFonts()
    }

    static func handleSDLQuit() {
        print("SDL_QUIT was called")
        shouldQuit = true
        window = nil
        glRenderer = nil
        unload()
        #if os(Android)
            try? jni.call("removeCallbacks", on: getSDLView())
        #endif
    }

    private static var onUnloadListeners: [() -> Void] = []
    public static func onUnload(_ callback: @escaping () -> Void) {
        onUnloadListeners.append(callback)
    }

    private static func unload() {
        onUnloadListeners.forEach { $0() }
        onUnloadListeners.removeAll()
        DisplayLink.activeDisplayLinks.removeAll()
        UIView.layersWithAnimations.removeAll()
        UIEvent.activeEvents.removeAll()
        UIView.currentAnimationPrototype = nil
        UIFont.fontRendererCache.removeAll()
    }

    private static var firstRender = true // screen is black until first touch if we don't check for this

    /// Returns: time taken (in milliseconds) to render current frame
    public static func render() -> Double {
        let frameTimer = Timer()
        doRender(at: frameTimer)
        if shouldQuit { return -1.0 }
        return frameTimer.elapsedTimeInMilliseconds
    }

    private static func doRender(at frameTimer: Timer) {
        let eventWasHandled = handleEventsIfNeeded()
        if shouldQuit { return }

        if !DisplayLink.activeDisplayLinks.isEmpty {
            DisplayLink.activeDisplayLinks.forEach { $0.callback() }
        } else if !eventWasHandled && !firstRender && !UIView.animationsArePending {
            // Sleep unless there are active touch inputs or pending animations
            return
        }

        UIView.animateIfNeeded(at: frameTimer)

        glRenderer.clear()

        GPU_MatrixMode(GPU_MODELVIEW)
        GPU_LoadIdentity()

        glRenderer.clippingRect = window.bounds
        window.sdlDrawAndLayoutTreeIfNeeded()
        window.layer.sdlRender()
        glRenderer.flip()

        firstRender = false
    }
}

#if os(Android)
private let maxFrameRenderTimeInMilliseconds = 1000.0 / 60.0

@_silgen_name("Java_org_libsdl_app_SDLActivity_nativeRender")
public func renderCalledFromJava(env: UnsafeMutablePointer<JNIEnv>, view: JavaObject) {
    let timeTaken = SDL.render()
    let remainingFrameTime = maxFrameRenderTimeInMilliseconds - timeTaken
   
    if remainingFrameTime > 0 {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, remainingFrameTime / 1000, true)
    }
}
#endif
