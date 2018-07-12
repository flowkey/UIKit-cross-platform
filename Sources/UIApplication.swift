//
//  UIApplication.swift
//  UIKit
//
//  Created by Geordie Jay on 10.07.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import Foundation

open class UIApplication {
    open static var shared: UIApplication! // set via UIApplicationMain(_:_:_:_:)

    open internal(set) var delegate: UIApplicationDelegate?
    open var isIdleTimerDisabled = false

    // TODO: use this for event handling instead of the custom SDL code we have now
    open func sendEvent(_ event: UIEvent) {}

    open var keyWindow: UIWindow? {
        didSet { keyWindow?.frame = UIScreen.main.bounds }
    }
    open var windows: [UIWindow] = []

    /// Currently not implemented but could be useful for Android
    open var statusBarStyle = UIStatusBarStyle.`default`

    // Useful in future: ?
    // open var preferredContentSizeCategory: UIContentSizeCategory { get }


    // MARK: Internals

    public required init() {
        UIFont.loadSystemFonts()
    }

    fileprivate var shouldQuit = false
    internal var glRenderer = GLRenderer()

    deinit {
        DisplayLink.activeDisplayLinks.removeAll()
        UIView.layersWithAnimations.removeAll()
        UIEvent.activeEvents.removeAll()
        UIView.currentAnimationPrototype = nil
        UIFont.clearCaches()
    }
}


import SDL
import SDL_gpu
import CoreFoundation

extension UIApplication {
    func handleSDLQuit() {
        print("SDL_QUIT was called")
        shouldQuit = true
        #if os(Android)
        try? jni.call("removeCallbacks", on: getSDLView())
        #elseif os(macOS)
        exit(0)
        #endif
    }

    func render(atTime frameTimer: Timer) {
        handleEventsIfNeeded()
        guard !shouldQuit, let keyWindow = keyWindow else {
            print("Not rendering because `keyWindow` was `nil` or `shouldQuit == true`")
            return
        }

        DisplayLink.activeDisplayLinks.forEach { $0.callback() }
        UIView.animateIfNeeded(at: frameTimer)
        // XXX: It's possible for drawing to crash if the context is invalid:
        keyWindow.sdlDrawAndLayoutTreeIfNeeded()

        guard CALayer.layerTreeIsDirty else {
            // Nothing changed, so we can leave the existing image on the screen.
            return
        }

        glRenderer.clear()

        GPU_MatrixMode(GPU_MODELVIEW)
        GPU_LoadIdentity()

        glRenderer.clippingRect = keyWindow.bounds
        keyWindow.layer.sdlRender()

        do {
            try glRenderer.flip()
            CALayer.layerTreeIsDirty = false
        } catch {
            print("glRenderer failed to render, reiniting")
            //UIApplication.restart()
        }
    }
}

public enum UIStatusBarStyle {
    case `default`, lightContent
}


#if os(Android)
import JNI

private let maxFrameRenderTimeInSeconds = 1.0 / 60.0

@_silgen_name("Java_org_libsdl_app_SDLActivity_nativeRender")
public func renderCalledFromJava(env: UnsafeMutablePointer<JNIEnv>, view: JavaObject) {
    let frameTime = Timer()
    UIApplication.shared.render(atTime: frameTime)
    let remainingFrameTime = maxFrameRenderTimeInSeconds - frameTime.elapsedTimeInSeconds
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, max(0.001, remainingFrameTime / 2), true)
}
#endif
