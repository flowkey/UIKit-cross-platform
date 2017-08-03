//
//  CABasicAnimation.swift
//  UIKit
//
//  Created by Geordie Jay on 06.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public let kCAFillModeForwards = "kCAFillModeForwards"

public class CABasicAnimation {

    public init(keyPath: AnimationProperty) {
        self.keyPath = keyPath
    }

    public var keyPath: AnimationProperty?
    public var fillMode: String?
    public var isRemovedOnCompletion = true
    public var duration: CGFloat = 0
    public var delay: CGFloat = 0
    public var fromValue: Any?
    public var toValue: Any?

    internal var timer: Timer?
    internal var progress: CGFloat { // always between 0 and 1
        let elapsedTime = max(CGFloat(timer?.getElapsedTimeInMilliseconds() ?? 0) - (delay * 1000), 0)
        return min(elapsedTime / (duration * 1000), 1)
    }

    public enum AnimationProperty: ExpressibleByStringLiteral {
        case frame, opacity, unknown
        public init(stringLiteral value: String) {
            switch value {
            case "frame": self = .frame
            case "opacity": self = .opacity
            default: self = .unknown
            }
        }
    }

}
