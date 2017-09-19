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

extension CAMediaTimingFunction {
    static func timingFunction(from options: UIViewAnimationOptions) -> CAMediaTimingFunction? {
        if options.contains(.curveEaseIn) {
            return .init(name: kCAMediaTimingFunctionEaseIn)
        } else if options.contains(.curveEaseOut) {
            return .init(name: kCAMediaTimingFunctionEaseOut)
        } else if options.contains(.curveEaseInOut) {
            return .init(name: kCAMediaTimingFunctionEaseInEaseOut)
        } else if options.contains(.curveDecay) {
            return .init(name: kCAMediaTimingFunctionExp)
        }

        return .init(name: kCAMediaTimingFunctionDefault)
    }
}
