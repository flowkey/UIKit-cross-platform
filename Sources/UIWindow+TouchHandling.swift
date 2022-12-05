//
//  UIWindow+TouchHandling.swift
//  UIKit
//
//  Created by Geordie Jay on 30.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

@_implementationOnly import SDL

protocol SDLEventWithCoordinates {
    var x: Int32 { get }
    var y: Int32 { get }
}

extension SDL_MouseButtonEvent: SDLEventWithCoordinates {}
extension SDL_MouseMotionEvent: SDLEventWithCoordinates {}

@MainActor
extension CGPoint {
    static func from(_ event: SDLEventWithCoordinates) -> CGPoint {
        return UIScreen.main.absolutePointInOwnCoordinates(x: CGFloat(event.x), y: CGFloat(event.y))
    }

    static func from(_ event: SDL_TouchFingerEvent) -> CGPoint {
        return CGPoint(x: CGFloat(event.x), y: CGFloat(event.y))
    }
}
