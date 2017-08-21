//
//  CASpringAnimationPrototype.swift
//  UIKit
//
//  Created by Michael Knoch on 21.08.17.
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
    ) -> CASpringAnimation {
        return CASpringAnimation(prototype: self, keyPath: keyPath, fromValue: fromValue, toValue: toValue)
    }
}
