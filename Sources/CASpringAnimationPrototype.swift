//
//  CASpringAnimationPrototype.swift
//  UIKit
//
//  Created by Michael Knoch on 18.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

class CASpringAnimationPrototype: CABasicAnimationPrototype {
    let damping: CGFloat
    let initialSpringVelocity: CGFloat

    init(duration: CGFloat, delay: CGFloat, damping: CGFloat, initialSpringVelocity: CGFloat, options: UIViewAnimationOptions) {
        self.damping = damping
        self.initialSpringVelocity = initialSpringVelocity
        super.init(duration: duration, delay: delay, options: options)
    }

    override func createAnimation(
        keyPath: AnimationProperty,
        fromValue: AnimatableProperty,
        toValue: AnimatableProperty
    ) -> CABasicAnimation {
        return CASpringAnimation(prototype: self, keyPath: keyPath, fromValue: fromValue, toValue: toValue)
    }
}

fileprivate extension CASpringAnimation {
    convenience init(prototype: CASpringAnimationPrototype,
         keyPath: AnimationProperty,
         fromValue: AnimatableProperty,
         toValue: AnimatableProperty
    ) {
        self.init(
            duration: prototype.duration,
            delay: prototype.delay,
            damping: prototype.damping,
            initialSpringVelocity: prototype.initialSpringVelocity,
            options: prototype.options
        )

        damping = prototype.damping
        initialSpringVelocity = prototype.initialSpringVelocity
        self.keyPath = keyPath
    }
}

