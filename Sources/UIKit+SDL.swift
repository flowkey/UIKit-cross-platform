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
        let windowOptions: SDLWindowFlags

        #if os(Android)
            // height/width are determined by the window when fullscreen:
            let SCREEN_WIDTH = 0
            let SCREEN_HEIGHT = 0

             windowOptions = [SDL_WINDOW_ALLOW_HIGHDPI, SDL_WINDOW_FULLSCREEN]
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

        window = Window(size: CGSize(width: SCREEN_WIDTH, height: SCREEN_HEIGHT), options: windowOptions)
        rootView.frame.size = window.size
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
                //SDL_Delay(16)
                //continue
            }

            window.clear()
            rootView.sdlRender()
            window.flip()

            firstRender = false
        }
    }

    deinit { SDL_Quit() }
}
