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
import struct Foundation.TimeInterval
import JNI

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

    private static func handleEventsIfNeeded() -> Bool {
        var eventWasHandled = false
        var e = SDL_Event()

        while SDL_PollEvent(&e) == 1 {
            switch SDL_EventType(rawValue: e.type) {
            case SDL_QUIT:
                print("SDL_QUIT was called")
                shouldQuit = true
                SDL.rootView = nil
                window = nil
                unload()
                #if os(Android)
                try? jni.call("removeCallbacks", on: getSDLView())
                #endif
                return true
            case SDL_MOUSEBUTTONDOWN:
                let touch = UITouch(touchId: 0, at: .from(e.button), in: SDL.rootView, timestamp: TimeInterval(e.button.timestamp))
                let event = UIEvent(touch: touch)
                UIWindow.main.sendEvent(event)
                eventWasHandled = true
            case SDL_MOUSEMOTION:
                if
                    let event = UIEvent.activeEvents.first,
                    let touch = event.allTouches?.first(where: { $0.touchId == Int(0) } )
                {
                    touch.updateAbsoluteLocation(.from(e.button))
                    touch.timestamp = TimeInterval(e.motion.timestamp)
                    touch.phase = .moved
                    UIWindow.main.sendEvent(event)
                }
                eventWasHandled = true
            case SDL_MOUSEBUTTONUP:
                if
                    let event = UIEvent.activeEvents.first,
                    let touch = event.allTouches?.first(where: { $0.touchId == Int(0) } )
                {
                    touch.phase = .ended
                    UIWindow.main.sendEvent(event)
                }
                eventWasHandled = true
            case SDL_KEYUP:
                let keyModifier = SDL_Keymod(UInt32(e.key.keysym.mod))
                if keyModifier.contains(KMOD_LSHIFT) || keyModifier.contains(KMOD_RSHIFT) {
                    switch e.key.keysym.sym {
                    case 43: // plus/multiply key
                        fallthrough
                    case 61: // plus/equals key
                        SDL.onPressPlus?()
                    case 45: // minus/dash key
                        SDL.onPressMinus?()
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
@_silgen_name("Java_org_libsdl_app_SDLActivity_nativeRender")
public func renderCalledFromJava(env: UnsafeMutablePointer<JNIEnv>, view: JavaObject) {
    let renderAndRunLoopTimer = Timer()
    let timeTaken = SDL.render()
    let remainingFrameTime = maxFrameRenderTimeInMilliseconds - timeTaken
   
    if remainingFrameTime > 0 {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, remainingFrameTime / 1000, true)
    }
}
#endif

