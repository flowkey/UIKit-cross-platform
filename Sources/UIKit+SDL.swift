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
    public internal(set) static var rootView: UIWindow!
    static var window: Window!

    fileprivate static var shouldQuit = false

    public static func initialize() {
        self.shouldQuit = false
        self.firstRender = true
        self.window = nil // triggers Window deinit to destroy previous Window

        let window = Window()
        if window.size == .zero {
            preconditionFailure("You need window dimensions to run")
        }

        self.window = window
        self.rootView = UIWindow(frame: CGRect(origin: .zero, size: window.size))
        UIFont.loadSystemFonts() // should always happen on UIKit-SDL init
    }

    static func handleSDLQuit() {
        print("SDL_QUIT was called")
        shouldQuit = true
        rootView = nil
        window = nil
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

        window.clear()

        GPU_MatrixMode(GPU_MODELVIEW)
        GPU_LoadIdentity()

        window.clippingRect = rootView.bounds
        rootView.sdlDrawAndLayoutTreeIfNeeded()
        rootView.layer.sdlRender()
        window.flip()

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
