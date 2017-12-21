//
//  UIKit.swift
//  sdl2testapinotes
//
//  Created by Geordie Jay on 11.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

import SDL
import SDL_gpu
import class Foundation.RunLoop
import struct Foundation.Date

private let timeBetweenFramesMS = 1000.0 / 60.0


final public class SDL { // XXX: only public for startRunLoop()
    static var rootView: UIWindow!
    static var window: Window!

    private static var shouldQuit = false
    private static var isRunning = false

    public static func initialize() {
        self.shouldQuit = false
        self.rootView = UIWindow()
        self.isRunning = false
        self.window = nil // triggers Window deinit to destroy previous Window

        let windowOptions: SDLWindowFlags

        #if os(Android)
            // height/width are determined by the window when fullscreen:
            let SCREEN_WIDTH = 0
            let SCREEN_HEIGHT = 0

            windowOptions = [SDL_WINDOW_FULLSCREEN]
        #else
            // This corresponds to the Samsung S7 screen at its 1080p 1.5x Retina resolution:
            let SCREEN_WIDTH = 2560 / 3
            let SCREEN_HEIGHT = 1440 / 3
            windowOptions = [
                SDL_WINDOW_ALLOW_HIGHDPI,
                //SDL_WINDOW_FULLSCREEN
            ]
        #endif

        SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "best")

        let window = Window(size: CGSize(width: SCREEN_WIDTH, height: SCREEN_HEIGHT), options: windowOptions)

        if window.size == .zero {
            preconditionFailure("You need window dimensions to run")
        }

        rootView.frame.size = window.size

        self.window = window
        UIFont.loadSystemFonts() // should always happen on UIKit-SDL init
    }

    public static func runWithRootView(_ view: UIView) {
        rootView.addSubview(view)
        startRunLoop()
    }

    public static func startRunLoop() {
        if isRunning == false {
            isRunning = true
            _startRunLoop()
        }
    }

    private static func _startRunLoop() {
        var firstRender = true // screen is black until first touch if we don't check for this
        let fpsView = MeteringView(metric: "FPS")
        fpsView.frame = CGRect(x: 0, y: 0, width: 150, height: 25)
        fpsView.frame.maxX = rootView.bounds.maxX
        fpsView.isUserInteractionEnabled = false
        fpsView.sizeToFit()
        rootView.addSubview(fpsView)

        var frameTimer = Timer()
        while (!shouldQuit) {
            defer {
                let remainingFrameTime = (timeBetweenFramesMS - frameTimer.getElapsedTimeInMilliseconds()) / 1000 // seconds
                let endOfCurrentFrame = Date(timeIntervalSinceNow: remainingFrameTime)
                RunLoop.current.run(until: endOfCurrentFrame)
                frameTimer = Timer() // reset for next frame
            }

            let eventWasHandled = handleEventsIfNeeded()

            if !DisplayLink.activeDisplayLinks.isEmpty {
                DisplayLink.activeDisplayLinks.forEach { $0.callback() }
            } else if !eventWasHandled && !firstRender && !UIView.animationsArePending {
                // We can avoid updating the screen at all unless there is active touch input
                // or animations are pending for execution
                continue
            }

            UIView.animateIfNeeded(at: frameTimer)

            window.clear()
            window.setShapeBlending(true)

            // fixes video surface visibility with transparent & opaque views in SDLSurface above
            // by changing the alpha blend function to: src-alpha * (1 - dst-alpha) + dst-alpha
            window.setShapeBlendMode(GPU_BLEND_NORMAL_FACTOR_ALPHA)
            rootView.sdlRender()
            window.flip()

            firstRender = false
            let frameTime = frameTimer.getElapsedTimeInMilliseconds()
            fpsView.addMeasurement(1000.0 / frameTime)
        }
    }

    private static func handleEventsIfNeeded() -> Bool {
        var eventWasHandled = false
        var e = SDL_Event()

        while SDL_PollEvent(&e) == 1 {
            switch SDL_EventType(rawValue: e.type) {
            case SDL_QUIT:
                shouldQuit = true
            case SDL_MOUSEBUTTONDOWN:
                handleTouchDown(.from(e.button))
                eventWasHandled = true
            case SDL_MOUSEMOTION:
                handleTouchMove(.from(e.motion))
                eventWasHandled = true
            case SDL_MOUSEBUTTONUP:
                handleTouchUp(.from(e.button))
                eventWasHandled = true
            default: break
            }
        }

        return eventWasHandled
    }
}

private func measure(_ function: @autoclosure () -> Void) -> Double {
    let timer = Timer()
    function()
    return timer.getElapsedTimeInMilliseconds()
}
