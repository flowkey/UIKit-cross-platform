//
//  CABasicAnimation.swift
//  UIKit
//
//  Created by Geordie Jay on 06.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public let kCAFillModeForwards = "kCAFillModeForwards"

public class CABasicAnimation: CAAction {
    // != nil means animating in UIView.animate closure
    // == nil means animation was manually instantiated
    var animationGroup: UIViewAnimationGroup? = UIView.currentAnimationGroup

    public init(keyPath: AnimationKeyPath) {
        self.keyPath = keyPath
    }

    init(
        prototype: CABasicAnimationPrototype,
        keyPath: AnimationKeyPath,
        fromValue: AnimatableProperty,
        timingFunction: CAMediaTimingFunction?
    ) {
        delay = prototype.delay
        duration = prototype.duration
        options = prototype.options
        self.keyPath = keyPath
        self.fromValue = fromValue
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

    public var keyPath: AnimationKeyPath?
    public var fillMode: String?
    public var isRemovedOnCompletion = true
    public var duration: CGFloat = 0
    public var delay: CGFloat = 0
    public var options: UIViewAnimationOptions = []
    public var timingFunction: CAMediaTimingFunction? = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)

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

extension CABasicAnimation: Equatable {
    public static func ==(lhs: CABasicAnimation, rhs: CABasicAnimation) -> Bool {
        return ObjectIdentifier(lhs).hashValue == ObjectIdentifier(rhs).hashValue
    }
}

