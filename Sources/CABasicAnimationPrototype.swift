//
//  CABasicAnimationPrototype.swift
//  UIKit
//
//  Created by Michael Knoch on 18.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

class CABasicAnimationPrototype {
    let duration: CGFloat
    let delay: CGFloat
    let animationGroup: UIViewAnimationGroup

    init(duration: CGFloat, delay: CGFloat, animationGroup: UIViewAnimationGroup) {
        self.delay = delay
        self.duration = duration
        self.animationGroup = animationGroup
    }

    func createAnimation(keyPath: AnimationKeyPath, fromValue: AnimatableProperty) -> CABasicAnimation {
        return CABasicAnimation(
            prototype: self,
            keyPath: keyPath,
            fromValue: fromValue,
            timingFunction: .timingFunction(from: animationGroup.options)
        )
    }
}
