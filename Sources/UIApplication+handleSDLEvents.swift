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
            if let uievent = UIEvent.from(e) {
                sendEvent(uievent)
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
                        UIApplication.restart()
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
        UIApplication.restart {
            if let runningApplication = UIApplication.shared {
                runningApplication.delegate?.applicationWillEnterForeground(runningApplication)
            }
        }
    }

    static func onDidEnterForeground() {
        if let runningApplication = UIApplication.shared {
            runningApplication.delegate?.applicationDidBecomeActive(runningApplication)
        }
    }

    static func onWillEnterBackground() {
        if let runningApplication = UIApplication.shared {
            runningApplication.delegate?.applicationWillResignActive(runningApplication)
        }
    }

    static func onDidEnterBackground() {
        if let runningApplication = UIApplication.shared {
            runningApplication.delegate?.applicationDidEnterBackground(runningApplication)
        }
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

extension UIEvent {
    static func from(_ event: SDL_Event) -> UIEvent? {
        switch SDL_EventType(event.type) {
        case SDL_FINGERDOWN:
            let newTouch = UITouch(
                touchId: Int(event.tfinger.fingerId),
                at: CGPoint(
                    x: CGFloat(event.tfinger.x),
                    y: CGFloat(event.tfinger.y)
                ),
                timestamp: event.timestampInSeconds
            )

            if
                let firstExistingEvent = UIEvent.activeEvents.first,
                let _ = firstExistingEvent.allTouches?.first(where: {$0.touchId == event.tfinger.fingerId})
            {
                // Found a matching event, adding current touch to it and returning
                firstExistingEvent.allTouches?.insert(newTouch)
                return firstExistingEvent
            } else {
                // No matching event found, creating a new one
                return UIEvent(touch: newTouch)
            }

        case SDL_FINGERMOTION:
            if
                let firstExistingEvent = UIEvent.activeEvents.first,
                let matchingTouch = firstExistingEvent.allTouches?.first(where: { $0.touchId == event.tfinger.fingerId})
            {

                matchingTouch.timestamp = event.timestampInSeconds
                matchingTouch.phase = .moved
                matchingTouch.updateAbsoluteLocation(.from(event.tfinger))
                return firstExistingEvent
            } else {
                return nil
            }

        case SDL_FINGERUP:
            if
                let firstExistingEvent = UIEvent.activeEvents.first,
                let matchingTouch = firstExistingEvent.allTouches?.first(where: {$0.touchId == event.tfinger.fingerId})
            {
                matchingTouch.timestamp = event.timestampInSeconds
                matchingTouch.phase = .ended
                return firstExistingEvent
            } else {
                return nil
            }

        default:
            return nil
        }
    }
}

extension UIEvent: CustomStringConvertible {
    public var description: String {
        var listOfTouches = ""
        if let touches = allTouches {
            for touch in touches {
                listOfTouches += "\(touch.description),\n"
            }
        }
        return "Event with touches: \(listOfTouches)"
    }
}

extension UITouch: CustomStringConvertible {
    public var description: String {
        return "TouchID: \(self.touchId), timestamp: \(self.timestamp)"
    }
}

#if os(Android)
import JNI

@_cdecl("Java_org_libsdl_app_SDLActivity_onNativeTouchUIKit")
public func onNativeTouch(
    env: UnsafeMutablePointer<JNIEnv>,
    view: JavaObject,
    touchDeviceID: JavaInt,
    pointerFingerID: JavaInt,
    action: JavaInt,
    x: JavaFloat,
    y: JavaFloat,
    pressure: JavaFloat,
    timestamp: JavaLong
) {
    guard let eventType = SDL_EventType.eventFrom(androidAction: action)
    else { return }

    var event = SDL_Event(tfinger:
        SDL_TouchFingerEvent(
            type: eventType.rawValue,
            timestamp: UInt32(timestamp), // ensure this is in ms
            touchId: Int64(touchDeviceID), // I think this is the "Touch Device ID" which should always be 0, but check this
            fingerId: Int64(pointerFingerID),
            x: x / Float(UIScreen.main.scale),
            y: y / Float(UIScreen.main.scale),
            dx: 0,
            dy: 0,
            pressure: pressure
        )
    )

    // add the event to SDL's event stack
    // don't use SDL_PushEvent because it overrides `event.timestamp` with its own:
    SDL_PeepEvents(&event, 1, SDL_ADDEVENT, 0, 0)
}

extension SDL_EventType {
    public static func eventFrom(androidAction: JavaInt) -> SDL_EventType? {
        switch androidAction {
        case 0, 5: return SDL_FINGERDOWN
        case 1, 6: return SDL_FINGERUP
        case 2: return SDL_FINGERMOTION
        default: return nil
        }
    }
}

#endif
