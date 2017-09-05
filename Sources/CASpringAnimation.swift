//
//  CASpringAnimation.swift
//  UIKit
//
//  Created by Michael Knoch on 08.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

class CASpringAnimation: CABasicAnimation {
    var damping: CGFloat?
    var initialSpringVelocity: CGFloat?

    init(from animation: CASpringAnimation) {
        damping = animation.damping
        initialSpringVelocity = animation.initialSpringVelocity

        super.init(from: animation)
    }

    init(prototype: CASpringAnimationPrototype,
         keyPath: AnimationKeyPath,
         fromValue: AnimatableProperty
    ) {
        damping = prototype.damping
        initialSpringVelocity = prototype.initialSpringVelocity

        super.init(
            prototype: prototype,
            keyPath: keyPath,
            fromValue: fromValue,
            timingFunction: .timingFunction(from: prototype.options)
        )
    }
}
