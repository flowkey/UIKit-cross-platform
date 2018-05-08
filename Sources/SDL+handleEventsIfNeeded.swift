//
//  SDL+handleEventsIfNeeded.swift
//  UIKit
//
//  Created by Geordie Jay on 20.03.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import SDL
import struct Foundation.TimeInterval

extension SDL {
    static func handleEventsIfNeeded() {
        var e = SDL_Event()

        while SDL_PollEvent(&e) == 1 {
            switch SDL_EventType(rawValue: e.type) {
            case SDL_QUIT:
                handleSDLQuit()
                return
            case SDL_MOUSEBUTTONDOWN:
                let touch = UITouch(touchId: 0, at: .from(e.button), in: window, timestamp: e.timestampInSeconds)
                let event = UIEvent(touch: touch)
                window.sendEvent(event)
            case SDL_MOUSEMOTION:
                if
                    let event = UIEvent.activeEvents.first,
                    let touch = event.allTouches?.first(where: { $0.touchId == Int(0) } )
                {
                    let previousTimestamp = touch.timestamp
                    let newTimestamp = e.timestampInSeconds

                    touch.updateAbsoluteLocation(.from(e.motion))
                    touch.timestamp = newTimestamp
                    touch.phase = .moved

                    // SDL adds timestamps on send which could be quite different to when the event actually occurred.
                    // It's common to get two events with an unrealistically small time between them; don't send those.
                    if (newTimestamp - previousTimestamp) > (5 / 1000) {
                        window.sendEvent(event)
                    }
                }
            case SDL_MOUSEBUTTONUP:
                if
                    let event = UIEvent.activeEvents.first,
                    let touch = event.allTouches?.first(where: { $0.touchId == Int(0) } )
                {
                    touch.timestamp = e.timestampInSeconds
                    touch.phase = .ended
                    window.sendEvent(event)
                }
            case SDL_KEYUP:
                #if DEBUG
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

                if keyModifier.contains(KMOD_LGUI) || keyModifier.contains(KMOD_RGUI) {
                    if e.key.keysym.sym == 114 { // CMD-R
                        SDL.initialize()
                    }
                }
                #endif

                let scancode = e.key.keysym.scancode
                if scancode == .androidHardwareBackButton || scancode == .escapeKey {
                    // If not handled already:
                    if window.deepestPresentedView().handleHardwareBackButtonPress() == false {
                        // This emulates the behaviour that UIApplication (which is what `SDL` should be) is actually the last responder in the responder chain.
                        SDL.onHardwareBackButtonPress?()
                    }
                }
            default:
                break
            }
        }
    }
}

extension SDL_Scancode {
    static let escapeKey = SDL_Scancode(rawValue: 41)
    static let androidHardwareBackButton = SDL_Scancode(rawValue: 270)
}

extension SDL {
    public static var onHardwareBackButtonPress: (() -> Void)?

    #if DEBUG
    public static var onPressPlus: (() -> Void)?
    public static var onPressMinus: (() -> Void)?
    #endif
}

extension SDL_Keymod: OptionSet {}

extension SDL_Event {
    var timestampInSeconds: TimeInterval {
        // SDL timestamps are in milliseconds intially:
        return TimeInterval(self.common.timestamp) / 1000
    }
}
