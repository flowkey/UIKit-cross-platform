//
//  UIEvent+fromSDL_Event.swift
//  UIKit
//
//  Created by Geordie Jay on 05.11.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import JNI
import SDL

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

            guard let existingTouchEvent = UIEvent.activeEvents.first(where: { $0.allTouches != nil }) else {
                return UIEvent(touch: newTouch)
            }

            assert(!existingTouchEvent.allTouches!.contains(where: { $0.touchId == event.tfinger.fingerId }),
                "The active event already has a touch with this fingerId, this should be impossible")

            existingTouchEvent.allTouches!.insert(newTouch)
            return existingTouchEvent

        case SDL_FINGERMOTION:
            if
                let existingTouchEvent = UIEvent.activeEvents.first(where: { $0.allTouches != nil }),
                let matchingTouch = existingTouchEvent.allTouches?.first(where: { $0.touchId == event.tfinger.fingerId })
            {
                matchingTouch.timestamp = event.timestampInSeconds
                matchingTouch.phase = .moved
                matchingTouch.updateAbsoluteLocation(.from(event.tfinger))
                return existingTouchEvent
            } else {
                assertionFailure("Got a motion event for a touch we know nothing about")
                return nil
            }

        case SDL_FINGERUP:
            if
                let firstExistingEvent = UIEvent.activeEvents.first(where: { $0.allTouches != nil }),
                let matchingTouch = firstExistingEvent.allTouches?.first(where: { $0.touchId == event.tfinger.fingerId })
            {
                matchingTouch.timestamp = event.timestampInSeconds
                matchingTouch.phase = .ended
                return firstExistingEvent
            } else {
                assertionFailure("Got a finger up event for a touch we know nothing about")
                return nil
            }

        default:
            return nil
        }
    }
}

extension UIEvent: CustomStringConvertible {
    public var description: String {
        let baseText = "UIEvent:"
        guard let allTouches = self.allTouches else {
            return baseText + " no touches"
        }

        return baseText + "\n" + allTouches.map { $0.description }.joined(separator: ",\n")
    }
}

extension UITouch: CustomStringConvertible {
    public var description: String {
        return "TouchID: \(self.touchId), timestamp: \(self.timestamp)"
    }
}

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
    guard let eventType = SDL_EventType.from(androidAction: action) else { return }

    var event = SDL_Event(tfinger:
        SDL_TouchFingerEvent(
            type: eventType.rawValue,
            timestamp: UInt32(timestamp), // the Android system provides timestamps in ms
            touchId: Int64(touchDeviceID), // seems to remain constant but actual value depends on phone/tablet
            fingerId: Int64(pointerFingerID),
            x: x / Float(UIScreen.main.scale),
            y: y / Float(UIScreen.main.scale),
            dx: 0, // Not used in UIKit cross platform:
            dy: 0, // Instead, we do these calculations in our UIGestureRecognizers etc.
            pressure: pressure
        )
    )

    // Add the event to SDL's event stack
    // Don't use SDL_PushEvent because that overrides `event.timestamp` with its own:
    SDL_PeepEvents(&event, 1, SDL_ADDEVENT, 0, 0)
}

extension SDL_EventType {
    public static func from(androidAction: JavaInt) -> SDL_EventType? {
        switch androidAction {
        case 0, 5: return SDL_FINGERDOWN
        case 1, 6: return SDL_FINGERUP
        case 2: return SDL_FINGERMOTION
        default: return nil
        }
    }
}
