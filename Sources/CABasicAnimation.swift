//
//  CABasicAnimation.swift
//  UIKit
//
//  Created by Geordie Jay on 06.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public let kCAFillModeForwards = "kCAFillModeForwards"

public class CABasicAnimation {

    // != nil means animating in UIView.animate closure
    // == nil means animation was manually instantiated
    var animationGroup = UIView.currentAnimationGroup

    public init(keyPath: AnimationProperty) {
        self.keyPath = keyPath
    }

    init(keyPath: AnimationProperty, protoType: CABasicAnimationPrototype) {
        self.keyPath = keyPath
        self.delay = protoType.delay
        self.duration = protoType.duration
    }

    public var keyPath: AnimationProperty?
    public var fillMode: String?
    public var isRemovedOnCompletion = true
    public var duration: CGFloat = 0
    public var delay: CGFloat = 0
    public var fromValue: AnimatableProperty?
    public var toValue: AnimatableProperty?

    private var timer = Timer()
    func progress(at currentTime: Timer) -> CGFloat { // always between 0 and 1
        let elapsedTime = max(CGFloat(currentTime - self.timer) - (delay * 1000), 0)
        return min(elapsedTime / (duration * 1000), 1)
    }

    func stop(finished: Bool) {
        animationGroup?.didStop(finished: finished)
    }
}

public enum AnimationProperty: ExpressibleByStringLiteral {
    case frame, opacity, bounds, unknown
    public init(stringLiteral value: String) {
        switch value {
        case "frame": self = .frame
        case "opacity": self = .opacity
        case "bounds": self = .bounds
        default: self = .unknown
        }
    }
}

public protocol AnimatableProperty {}

protocol CABasicAnimationDelegate: class {
    func didStop(finished: Bool)
}

