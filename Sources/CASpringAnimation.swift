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
        delay: CGFloat,
        duration: CGFloat,
        damping: CGFloat,
        initialSpringVelocity: CGFloat,
        options: UIViewAnimationOptions
    ) {
        self.damping = damping
        self.initialSpringVelocity = initialSpringVelocity
        super.init(duration: duration, delay: delay, options: options)
    }

    init(prototype: CASpringAnimation, keyPath: AnimationProperty) {
        damping = prototype.damping
        initialSpringVelocity = prototype.initialSpringVelocity

        super.init(keyPath: keyPath)

        duration = prototype.duration
        delay = prototype.delay
        options = prototype.options
    }

    override func createAnimation(keyPath: AnimationProperty) -> CASpringAnimation {
        return CASpringAnimation(prototype: self, keyPath: keyPath)
    }
}
