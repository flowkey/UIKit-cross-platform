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
import struct Foundation.Date
import class Foundation.Thread

private let maxFrameRenderTimeInMilliseconds = 1000.0 / 60.0

final public class SDL { // Only public for rootView!
    public private(set) static var rootView: UIWindow!
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

    private static var onUnloadListeners: [() -> Void] = []
    public static func onUnload(_ callback: @escaping () -> Void) {
        onUnloadListeners.append(callback)
    }

    private static func unload() {
        onUnloadListeners.forEach { $0() }
        onUnloadListeners.removeAll()
        DisplayLink.activeDisplayLinks.removeAll()
        UIView.layersWithAnimations.removeAll()
        UITouch.activeTouches.removeAll()
        UIView.currentAnimationPrototype = nil
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
        rootView.sdlDrawAndLayoutTreeIfNeeded()
        rootView.layer.sdlRender()
        window.flip()

        firstRender = false
    }

    private static func handleEventsIfNeeded() -> Bool {
        var eventWasHandled = false
        var e = SDL_Event()

        while SDL_PollEvent(&e) == 1 {
            switch SDL_EventType(rawValue: e.type) {
            case SDL_QUIT:
                print("SDL_QUIT was called")
                shouldQuit = true
                SDL.rootView = UIWindow()
                window = nil
                unload()
                return true
            case SDL_MOUSEBUTTONDOWN:
                handleTouchDown(.from(e.button))
                eventWasHandled = true
            case SDL_MOUSEMOTION:
                handleTouchMove(.from(e.motion))
                eventWasHandled = true
            case SDL_MOUSEBUTTONUP:
                handleTouchUp(.from(e.button))
                eventWasHandled = true
            case SDL_KEYUP:
                let keyModifier = SDL_Keymod(UInt32(e.key.keysym.mod))
                if keyModifier.contains(KMOD_LSHIFT) || keyModifier.contains(KMOD_RSHIFT) {
                    switch e.key.keysym.sym {
                    case 61: // plus/equals key
                        SDL.onPressPlus?()
                    case 45: // minus/dash key
                        SDL.onPressMinus?()
                    default:
                        break
                    }
                }
            default: break
            }
        }

        return eventWasHandled
    }
}


extension SDL {
    public static var onPressPlus: (() -> Void)?
    public static var onPressMinus: (() -> Void)?
}

extension SDL_Keymod: OptionSet {}

#if os(Android)
import JNI

@_silgen_name("Java_org_libsdl_app_SDLActivity_render")
public func renderCalledFromJava(env: UnsafeMutablePointer<JNIEnv>, view: JavaObject) -> JavaInt {
    let renderAndRunLoopTimer = Timer()
    let timeTaken = SDL.render()
    let remainingFrameTime = maxFrameRenderTimeInMilliseconds - timeTaken
   
    if remainingFrameTime > 0 {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, remainingFrameTime / 1000, true)
    }

    // XXX: This really should send back either a float or a nanosecond int value
    // Because rounding up to 17 or down to 16 introduces too much variation for a fluid FPS
    return JavaInt(renderAndRunLoopTimer.elapsedTimeInMilliseconds)
}
#endif

