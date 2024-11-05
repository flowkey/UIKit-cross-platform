//
//  SDL+handleEventsIfNeeded.swift
//  UIKit
//
//  Created by Geordie Jay on 20.03.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import SDL

#if os(Android)
import JNI
#endif

extension UIApplication {
    @MainActor
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
                    let touch = event.allTouches?.first(where: { $0.touchId == 0 })
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
                    let touch = event.allTouches?.first(where: { $0.touchId == 0 })
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
                    _ = keyWindow?.deepestPresentedView().handleHardwareBackButtonPress()
                }
            case SDL_APP_WILLENTERBACKGROUND:
                UIApplication.onWillEnterBackground()
            case SDL_APP_DIDENTERBACKGROUND:
                UIApplication.onDidEnterBackground()
            case SDL_APP_WILLENTERFOREGROUND:
                UIApplication.onWillEnterForeground()
            case SDL_APP_DIDENTERFOREGROUND:
                UIApplication.onDidEnterForeground()
            case SDL_WINDOWEVENT:
                let windowEventId = SDL_WindowEventID(UInt32(e.window.event))

                guard windowEventId == SDL_WINDOWEVENT_RESIZED else {
                    break
                }

                // Initialize UIScreen in @1x pixels on Android due to SDL quirks on that platform; retina points on Mac
                #if os(Android)
                let newWidth = CGFloat(e.window.data1) / UIScreen.main.scale
                let newHeight = CGFloat(e.window.data2) / UIScreen.main.scale
                #else
                let newWidth = CGFloat(e.window.data1)
                let newHeight = CGFloat(e.window.data2)
                #endif

                let newSize = CGSize(width: newWidth, height: newHeight)
                UIScreen.main.bounds.size = newSize
                
                let newRect = CGRect(origin: .zero, size: newSize)
                UIApplication.shared.keyWindow!.frame = newRect // sets needsLayout of keyWindow to true
                UIApplication.shared.delegate?.window?.rootViewController?.view.frame = newRect

            default:
                break
            }
        }
    }
}

extension UIApplication {
    @MainActor
    class func onWillEnterForeground() {
        #if os(Android)
        if UIScreen.main == nil { // sometimes we "enter foreground" after just a loss of focus
            UIScreen.main = UIScreen()
        }
        #endif

        UIApplication.shared?.delegate?.applicationWillEnterForeground(UIApplication.shared)
        UIApplication.post(willEnterForegroundNotification)
    }

    @MainActor
    class func onDidEnterForeground() {
        UIApplication.shared?.delegate?.applicationDidBecomeActive(UIApplication.shared)
        UIApplication.post(didBecomeActiveNotification)
    }

    @MainActor
    class func onWillEnterBackground() {
        UIApplication.shared?.delegate?.applicationWillResignActive(UIApplication.shared)
        UIApplication.post(willResignActiveNotification)
    }

    @MainActor
    class func onDidEnterBackground() {
        UIApplication.shared?.delegate?.applicationDidEnterBackground(UIApplication.shared)
        UIApplication.post(didEnterBackgroundNotification)

        #if os(Android)
        UIScreen.main = nil
        #endif
    }
}

private extension UIApplication {
    class func post(_ name: Notification.Name) {
        // don't post UIApplication.shared as the object because object must be an NSObject as of Swift 5
        NotificationCenter.default.post(name: name, object: nil)
    }
}

extension SDL_Scancode {
    static let escapeKey = SDL_Scancode(rawValue: 41)
    static let androidHardwareBackButton = SDL_Scancode(rawValue: 270)
}

extension SDL_Keymod: OptionSet {}

extension SDL_Event {
    var timestampInSeconds: Double {
        // SDL timestamps are in milliseconds intially:
        return Double(self.common.timestamp) / 1000
    }
}

extension UIEvent {
    @MainActor
    static func from(_ event: SDL_Event) -> UIEvent? {
        switch SDL_EventType(event.type) {
        case SDL_FINGERDOWN:
            // XXX: minimal implementation for single touch
            guard UIEvent.activeEvents.isEmpty else {
                return nil
            }

            let newTouch = UITouch(
                touchId: 0,
                at: CGPoint(
                    x: CGFloat(event.tfinger.x),
                    y: CGFloat(event.tfinger.y)
                ),
                timestamp: event.timestampInSeconds
            )

            return UIEvent(touch: newTouch)

        case SDL_FINGERMOTION:
            if
                let firstExistingEvent = UIEvent.activeEvents.first,
                let matchingTouch = firstExistingEvent.allTouches?.first(where: { $0.touchId == event.tfinger.fingerId })
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
                let matchingTouch = firstExistingEvent.allTouches?.first(where: { $0.touchId == event.tfinger.fingerId })
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
    @MainActor public var description: String {
        let text = "Event with touches: "
        guard let allTouches = self.allTouches else {
            return text + "none"
        }
        let descriptions = allTouches.map { $0.description }
        return text + descriptions.joined(separator: ",\n")
    }
}

extension UITouch: CustomStringConvertible {
    public var description: String {
        return "TouchID: \(self.touchId), timestamp: \(self.timestamp)"
    }
}

#if os(Android)
#if os(Android)
import JNI
#endif

@_cdecl("Java_org_libsdl_app_SDLActivity_onNativeTouchUIKit")
public func onNativeTouch(
    env: UnsafeMutablePointer<JNIEnv?>?,
    view: JavaObject?,
    touchParameters: JavaObject
) {
    let touchDeviceId: JavaInt = try! jni.GetField("touchDeviceId", from: touchParameters)
    let pointerFingerId: JavaInt = try! jni.GetField("pointerFingerId", from: touchParameters)
    let action: JavaInt = try! jni.GetField("action", from: touchParameters)
    let x: JavaFloat = try! jni.GetField("x", from: touchParameters)
    let y: JavaFloat = try! jni.GetField("y", from: touchParameters)
    let pressure: JavaFloat = try! jni.GetField("pressure", from: touchParameters)
    let timestampMs: JavaLong = try! jni.GetField("timestamp", from: touchParameters)

    guard let eventType = SDL_EventType.eventFrom(androidAction: action)
    else { return }

    Task { @MainActor in
        guard let screenScale = UIScreen.main?.scale else { return }

        var event = SDL_Event(tfinger:
            SDL_TouchFingerEvent(
                type: eventType.rawValue,
                timestamp: UInt32(truncatingIfNeeded: timestampMs),
                touchId: Int64(touchDeviceId), // a seemingly arbitrary number, stays the same per device
                fingerId: Int64(pointerFingerId),
                x: x / Float(screenScale),
                y: y / Float(screenScale),
                dx: 0,
                dy: 0,
                pressure: pressure
            )
        )

        // add the event to SDL's event stack
        // don't use SDL_PushEvent because it overrides `event.timestamp` with its own:
        SDL_PeepEvents(&event, 1, SDL_ADDEVENT, 0, 0)
    }
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
