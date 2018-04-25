//
//  AnimationKeyPath.swift
//  UIKit
//
//  Created by Michael Knoch on 01.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public enum AnimationKeyPath: String, ExpressibleByStringLiteral {
    case backgroundColor, opacity, bounds, transform, position, anchorPoint, unknown

    public init(stringLiteral value: String) {
        switch value {
        case "backgroundColor": self = .backgroundColor
        case "opacity": self = .opacity
        case "bounds": self = .bounds
        case "transform": self = .transform
        case "position": self = .position
        case "anchorPoint": self = .anchorPoint
        default:
            assertionFailure("unknown AnimationKeyPath")
            self = .unknown
        }
    }
}
