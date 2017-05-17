//
//  UIKit.swift
//  sdl2testapinotes
//
//  Created by Geordie Jay on 11.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

import SDL

final public class SDL { // XXX: only public for startRunLoop()
    // Not private but can't be accessed directly outside of extensions because SDL.shared is private:
    let window: Window
    let rootView = UIWindow()

    private var update: (() -> Void)?

    static private let shared = SDL()
    static var window: Window { return SDL.shared.window }
    static var rootView: UIWindow { return SDL.shared.rootView }

    static var update: (() -> Void)? {
        get { return SDL.shared.update }
        set { SDL.shared.update = newValue }
    }

    public static func startRunLoop() {
        if SDL.shared.isRunning == false {
            SDL.shared.isRunning = true
            SDL.shared.startRunLoop()
        }
    }

    public static func initialize() {
        SDL.shared.window.clear() // do something random to ensure that `SDL.shared` exists
    }

    private init() {
        let windowOptions: SDLWindow.Options

        #if os(Android)
            // XXX: Get the screen dimensions (via displayMode?)
            // Samsung galaxy S7 resolution (`/ 2` for retina)
            let SCREEN_WIDTH = Int32(1920 / 2)
            let SCREEN_HEIGHT = Int32(1080 / 2)

             windowOptions = [SDL_WINDOW_ALLOW_HIGHDPI, SDL_WINDOW_FULLSCREEN]
        #else
            // Samsung galaxy S7 resolution (`/ 2` for retina)
            let SCREEN_WIDTH = Int32(2560 / 2)
            let SCREEN_HEIGHT = Int32(1440 / 2)
            windowOptions = [SDL_WINDOW_ALLOW_HIGHDPI]
        #endif

        window = Window(size: CGSize(width: Int(SCREEN_WIDTH), height: Int(SCREEN_HEIGHT)), options: windowOptions)

        rootView.frame.height = CGFloat(SCREEN_HEIGHT)
        rootView.frame.width = CGFloat(SCREEN_WIDTH)

        GPU_SetDebugLevel(GPU_DEBUG_LEVEL_MAX);
        SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "best")
    }

    private var isRunning = false
    private var shouldQuit = false
    var e = SDL_Event()

    func startRunLoop() {
        var firstRender = true // screen is black until first touch if we don't check for this

        while (!shouldQuit) {
            var eventWasHandled = false
            while SDL_PollEvent(&e) == 1 {
                switch SDL_EventType(rawValue: e.type) {
                case SDL_QUIT:
                    shouldQuit = true
                case SDL_MOUSEBUTTONDOWN:
                    handleTouchDown(e.button)
                    eventWasHandled = true
                case SDL_MOUSEMOTION:
                    handleTouchMove(e.motion)
                    eventWasHandled = true
                case SDL_MOUSEBUTTONUP:
                    handleTouchUp(e.button)
                    eventWasHandled = true
                default:
                    break
                }
            }

            if let update = update { // update exists when a DisplayLink is active
                update()
            } else if !eventWasHandled && !firstRender {
                // We can avoid updating the screen at all unless there is active touch input
                // or a running animation. We still need to handle the case of animations here!
                SDL_Delay(16)
                continue
            }

            window.clear()
            rootView.sdlRender()
            window.flip()

            firstRender = false
        }
    }

    deinit { SDL_Quit() }
}
