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
        self.rootView.backgroundColor = .purple
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

        GPU_MatrixMode(GPU_PROJECTION)
        GPU_LoadIdentity()

        GPU_MatrixMode(GPU_MODELVIEW)
        GPU_LoadIdentity()

        window.clippingRect = rootView.bounds
        rootView.sdlDrawAndLayoutTreeIfNeeded()
        rootView.layer.sdlRender()
        window.flip()

        assert(CATransform3D(unsafePointer: GPU_GetCurrentMatrix()) == CATransform3DIdentity,
               "We always return to the previous matrix after rendering a layer (and its sublayers), so something went wrong here")

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
                    case 112: // "P"
                        SDL.window.printThisLoop = true
                    case 118: // "V"
                        SDL.rootView.printViewHierarchy()
                    default:
                        print(e.key.keysym.sym)
                        break
                    }
                }
                if e.key.keysym.scancode.rawValue == 270 {
                    onHardwareBackButtonPress?()
                }
            default:
                break
            }
        }

        return eventWasHandled
    }
}

extension UIView {
    func printViewHierarchy(depth: Int = 0) {
        if self.isHidden || self.alpha < 0.01 { return }
        let indentation = (0 ..< depth).reduce("") { result, _ in result + "  " }
        print(indentation + "💩 " + self.description.replacingOccurrences(of: "\n", with: "\n" + indentation))

        let newDepth = depth + 1
        for subview in subviews {
            subview.printViewHierarchy(depth: newDepth)
        }
    }
}

extension SDL {
    public static var onPressPlus: (() -> Void)?
    public static var onPressMinus: (() -> Void)?
}

extension SDL_Keymod: OptionSet {}
public var onHardwareBackButtonPress: (() -> Void)?

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

