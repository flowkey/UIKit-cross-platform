//
//  CABasicAnimation.swift
//  UIKit
//
//  Created by Geordie Jay on 06.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public let kCAFillModeForwards = "kCAFillModeForwards"

public class CABasicAnimation: CAAction {

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
        animationGroup = prototype.animationGroup

        self.keyPath = keyPath
        self.fromValue = fromValue
        self.timingFunction = timingFunction
    }

    init(from animation: CABasicAnimation) {
        keyPath = animation.keyPath
        duration = animation.duration
        delay = animation.delay
        timer = animation.timer
        fillMode = animation.fillMode
        fromValue = animation.fromValue
        toValue = animation.toValue
        animationGroup = animation.animationGroup
        isRemovedOnCompletion = animation.isRemovedOnCompletion
        timingFunction = animation.timingFunction
    }

    func copy() -> CABasicAnimation {
        return CABasicAnimation(from: self)
    }

    /// animation duration in seconds
    public var duration: CGFloat = 0

    /// animation delay in seconds
    public var delay: CGFloat = 0

    public var keyPath: AnimationKeyPath?
    public var fillMode: String?
    public var isRemovedOnCompletion = true
    public var options: UIViewAnimationOptions = []
    public var timingFunction: CAMediaTimingFunction? = .init(name: kCAMediaTimingFunctionDefault)

    public var fromValue: AnimatableProperty?
    public var toValue: AnimatableProperty?

    var animationGroup: UIViewAnimationGroup?
    var timer = Timer()
}
