//
//  AnimationPrototypes.swift
//  UIKit
//
//  Created by Michael Knoch on 18.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

class CABasicAnimationPrototype {
    let duration: CGFloat
    let delay: CGFloat
    let options: UIViewAnimationOptions

    init(duration: CGFloat, delay: CGFloat, options: UIViewAnimationOptions) {
        self.delay = delay
        self.duration = duration
        self.options = options
    }

    func createAnimation(
        keyPath: AnimationProperty,
        fromValue: AnimatableProperty,
        toValue: AnimatableProperty
    ) -> CABasicAnimation {
        return CABasicAnimation(prototype: self, keyPath: keyPath, fromValue: fromValue, toValue: toValue)
    }
}

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
