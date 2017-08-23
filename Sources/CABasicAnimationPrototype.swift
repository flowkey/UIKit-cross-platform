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
        return CABasicAnimation(
            prototype: self,
            keyPath: keyPath,
            fromValue: fromValue,
            toValue: toValue,
            timingFunction: .timingFunction(from: options)
        )
    }
}
