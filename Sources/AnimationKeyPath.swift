//
//  AnimationKeyPath.swift
//  UIKit
//
//  Created by Michael Knoch on 01.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public enum AnimationKeyPath: String, ExpressibleByStringLiteral {
    case frame, opacity, bounds, transform, unknown

    public init(stringLiteral value: String) {
        switch value {
        case "frame": self = .frame
        case "opacity": self = .opacity
        case "bounds": self = .bounds
        case "transform": self = .transform
        default:
            assertionFailure("unknown AnimationKeyPath")
            self = .unknown
        }
    }
}
