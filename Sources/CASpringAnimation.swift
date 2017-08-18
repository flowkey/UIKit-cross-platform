//
//  CASpringAnimation.swift
//  UIKit
//
//  Created by Michael Knoch on 08.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

class CASpringAnimation: CABasicAnimation {
    var damping: CGFloat
    var initialSpringVelocity: CGFloat

    init(
        duration: CGFloat,
        delay: CGFloat,
        damping: CGFloat,
        initialSpringVelocity: CGFloat,
        options: UIViewAnimationOptions
    ) {
        self.damping = damping
        self.initialSpringVelocity = initialSpringVelocity
        super.init(duration: duration, delay: delay, options: options)
    }

    init(from animation: CASpringAnimation) {
        damping = animation.damping
        initialSpringVelocity = animation.initialSpringVelocity

        super.init(from: animation)
    }

    init(prototype: CASpringAnimationPrototype,
         keyPath: AnimationProperty,
         fromValue: AnimatableProperty,
         toValue: AnimatableProperty
    ) {
        self.damping = prototype.damping
        self.initialSpringVelocity = prototype.initialSpringVelocity
        
        super.init(prototype: prototype, keyPath: keyPath, fromValue: fromValue, toValue: toValue)
    }
}
