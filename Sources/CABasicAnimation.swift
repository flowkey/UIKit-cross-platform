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
    var animationGroup: UIViewAnimationGroup? = UIView.currentAnimationGroup

    public init(keyPath: AnimationProperty) {
        self.keyPath = keyPath
    }

    init(
        prototype: CABasicAnimationPrototype,
        keyPath: AnimationProperty,
        fromValue: AnimatableProperty,
        toValue: AnimatableProperty,
        timingFunction: CAMediaTimingFunction?
    ) {
        delay = prototype.delay
        duration = prototype.duration
        options = prototype.options
        self.keyPath = keyPath
        self.fromValue = fromValue
        self.toValue = toValue
        self.timingFunction = timingFunction
    }

    init(from animation: CABasicAnimation) {
        self.keyPath = animation.keyPath
        self.duration = animation.duration
        self.delay = animation.delay
        self.options = animation.options
        self.timer = animation.timer
        self.progress = animation.progress
        self.fillMode = animation.fillMode
        self.fromValue = animation.fromValue
        self.toValue = animation.toValue
        self.animationGroup = animation.animationGroup
        self.isRemovedOnCompletion = animation.isRemovedOnCompletion
        self.timingFunction = animation.timingFunction
    }

    func copy() -> CABasicAnimation {
        return CABasicAnimation(from: self)
    }

    public var keyPath: AnimationProperty?
    public var fillMode: String?
    public var isRemovedOnCompletion = true
    public var duration: CGFloat = 0
    public var delay: CGFloat = 0
    public var options: UIViewAnimationOptions = []
    public var timingFunction: CAMediaTimingFunction? = try! CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)

    public var fromValue: AnimatableProperty?
    public var toValue: AnimatableProperty?

    var timer = Timer()
    var progress: CGFloat = 0

    var hasStarted: Bool {
        return progress > 0
    }

    var isComplete: Bool {
        return progress == 1
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

extension CABasicAnimation: Equatable {
    public static func ==(lhs: CABasicAnimation, rhs: CABasicAnimation) -> Bool {
        return ObjectIdentifier(lhs).hashValue == ObjectIdentifier(rhs).hashValue
    }
}

