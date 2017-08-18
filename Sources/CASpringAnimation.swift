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

    init(from animation: CASpringAnimation, keyPath: AnimationProperty) {
        damping = animation.damping
        initialSpringVelocity = animation.initialSpringVelocity

        super.init(keyPath: keyPath)

        duration = animation.duration
        delay = animation.delay
        options = animation.options
    }

    override func createAnimation(keyPath: AnimationProperty) -> CASpringAnimation {
        return CASpringAnimation(from: self, keyPath: keyPath)
    }
}
