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

    public static var isInitialized: Bool {
        return window != nil && glRenderer != nil
    }

    public static func initialize() {
        self.shouldQuit = false
        self.glRenderer = nil // triggers GLRenderer deinit

        self.glRenderer = GLRenderer()
        self.window = UIWindow(frame: CGRect(origin: .zero, size: self.glRenderer.size))
        window.rootViewController = UIViewController(nibName: nil, bundle: nil)
        window.makeKeyAndVisible()

        UIFont.loadSystemFonts()
    }

    static func handleSDLQuit() {
        print("SDL_QUIT was called")
        shouldQuit = true
        unload() // unload first so deinit succeeds on e.g. `GPU_Image`s
        window = nil
        glRenderer = nil
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

    /// Returns: time taken (in milliseconds) to render current frame
    public static func render() -> Double {
        let frameTimer = Timer()
        doRender(at: frameTimer)
        if shouldQuit { return -1.0 }
        return frameTimer.elapsedTimeInMilliseconds
    }

    private static func doRender(at frameTimer: Timer) {
        handleEventsIfNeeded()
        if shouldQuit { return }

        DisplayLink.activeDisplayLinks.forEach { $0.callback() }
        UIView.animateIfNeeded(at: frameTimer)
        window.sdlDrawAndLayoutTreeIfNeeded()

        guard CALayer.layerTreeIsDirty else {
            // Nothing changed, so we can leave the existing image on the screen.
            return
        }

        glRenderer.clear()

        GPU_MatrixMode(GPU_MODELVIEW)
        GPU_LoadIdentity()

        glRenderer.clippingRect = window.bounds
        window.layer.sdlRender()
        glRenderer.flip()

        CALayer.layerTreeIsDirty = false
    }
}

#if os(Android)
private let maxFrameRenderTimeInMilliseconds = 1000.0 / 60.0

@_silgen_name("Java_org_libsdl_app_SDLActivity_nativeRender")
public func renderCalledFromJava(env: UnsafeMutablePointer<JNIEnv>, view: JavaObject) {
    guard SDL.window != nil else {
        assertionFailure("Attempted to render while the window was nil")
        return
    }

    let timeTaken = SDL.render()
    let remainingFrameTime = maxFrameRenderTimeInMilliseconds - timeTaken
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, max(0.001, remainingFrameTime / 1000), true)
}
#endif
