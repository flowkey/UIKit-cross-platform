//
//  AnimationKeyPath.swift
//  UIKit
//
//  Created by Michael Knoch on 01.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public enum AnimationKeyPath: String, ExpressibleByStringLiteral {
    case backgroundColor, opacity, bounds, transform, position, anchorPoint, unknown
    case transformScale = "transform.scale"
    case transformScaleX = "transform.scale.x"

    public init(stringLiteral value: String) {
        switch value {
        case "backgroundColor": self = .backgroundColor
        case "opacity": self = .opacity
        case "bounds": self = .bounds
        case "transform": self = .transform
        case "transform.scale": self = .transformScale
        case "transform.scale.x": self = .transformScaleX
        case "position": self = .position
        case "anchorPoint": self = .anchorPoint
        default:
            assertionFailure("unknown AnimationKeyPath")
            self = .unknown
        }
    }
}
