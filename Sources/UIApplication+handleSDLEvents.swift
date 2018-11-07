//
//  SDL+handleEventsIfNeeded.swift
//  UIKit
//
//  Created by Geordie Jay on 20.03.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import SDL
import struct Foundation.TimeInterval

extension UIApplication {
    func handleEventsIfNeeded() {
        var e = SDL_Event()

        while SDL_PollEvent(&e) == 1 {

            #if os(Android)
            if let uiEvent = UIEvent.from(e) {
                sendEvent(uiEvent)
                break
            }
            #endif

            switch SDL_EventType(rawValue: e.type) {
            case SDL_QUIT:
                handleSDLQuit()
                return
            case SDL_MOUSEBUTTONDOWN:
                let touch = UITouch(touchId: 0, at: .from(e.button), timestamp: e.timestampInSeconds)
                let event = UIEvent(touch: touch)
                sendEvent(event)
            case SDL_MOUSEMOTION:
                if
                    let event = UIEvent.activeEvents.first,
                    let touch = event.allTouches?.first(where: { $0.touchId == Int(0) })
                {
                    let previousTimestamp = touch.timestamp
                    let newTimestamp = e.timestampInSeconds

                    touch.updateAbsoluteLocation(.from(e.motion))
                    touch.timestamp = newTimestamp
                    touch.phase = .moved

                    // SDL adds timestamps on send which could be quite different to when the event actually occurred.
                    // It's common to get two events with an unrealistically small time between them; don't send those.
                    if (newTimestamp - previousTimestamp) > (5 / 1000) {
                        sendEvent(event)
                    }
                }
            case SDL_MOUSEBUTTONUP:
                if
                    let event = UIEvent.activeEvents.first,
                    let touch = event.allTouches?.first(where: { $0.touchId == Int(0) })
                {
                    touch.timestamp = e.timestampInSeconds
                    touch.phase = .ended
                    sendEvent(event)
                }
            case SDL_KEYUP:
                #if DEBUG
                let keyModifier = SDL_Keymod(UInt32(e.key.keysym.mod))
                if keyModifier.contains(KMOD_LSHIFT) || keyModifier.contains(KMOD_RSHIFT) {
                    switch e.key.keysym.sym {
                    case 43, 61: // +/*, +/= keys. TODO send key events via UIEvent
                        break
                    case 45: break // -/_ key
                    case 118: // "V"
                        keyWindow?.printViewHierarchy()
                    default:
                        print(e.key.keysym.sym)
                    }
                }

                if keyModifier.contains(KMOD_LGUI) || keyModifier.contains(KMOD_RGUI) {
                    if e.key.keysym.sym == 114 { // CMD-R
                        UIScreen.main = nil
                        UIScreen.main = UIScreen()
                    }
                }
                #endif

                let scancode = e.key.keysym.scancode
                if scancode == .androidHardwareBackButton || scancode == .escapeKey {
                    keyWindow?.deepestPresentedView().handleHardwareBackButtonPress()
                }
            case SDL_APP_WILLENTERBACKGROUND:
                UIApplication.onWillEnterBackground()
            case SDL_APP_DIDENTERBACKGROUND:
                UIApplication.onDidEnterBackground()
            case SDL_APP_WILLENTERFOREGROUND:
                UIApplication.onWillEnterForeground()
            case SDL_APP_DIDENTERFOREGROUND:
                UIApplication.onDidEnterForeground()
            default:
                break
            }
        }
    }
}

extension UIApplication {
    static func onWillEnterForeground() {
        #if os(Android)
        if UIScreen.main == nil { // sometimes we "enter foreground" after just a loss of focus
            UIScreen.main = UIScreen()
        }
        #endif

        UIApplication.shared?.delegate?.applicationWillEnterForeground(UIApplication.shared)
    }

    static func onDidEnterForeground() {
        UIApplication.shared?.delegate?.applicationDidBecomeActive(UIApplication.shared)
    }

    static func onWillEnterBackground() {
        UIApplication.shared?.delegate?.applicationWillResignActive(UIApplication.shared)
    }

    static func onDidEnterBackground() {
        UIApplication.shared?.delegate?.applicationDidEnterBackground(UIApplication.shared)

        #if os(Android)
        UIScreen.main = nil
        #endif
    }
}

extension SDL_Scancode {
    static let escapeKey = SDL_Scancode(rawValue: 41)
    static let androidHardwareBackButton = SDL_Scancode(rawValue: 270)
}

extension SDL_Keymod: OptionSet {}

extension SDL_Event {
    var timestampInSeconds: TimeInterval {
        // SDL timestamps are in milliseconds intially:
        return TimeInterval(self.common.timestamp) / 1000
    }
}
