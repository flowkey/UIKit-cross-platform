//
//  AnimationPrototype.swift
//  UIKit
//
//  Created by Michael Knoch on 08.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

protocol AnimationPrototype {
    var delay: CGFloat { get }
    var duration: CGFloat { get }
    var options: UIViewAnimationOptions { get }
    func createAnimation(keyPath: AnimationProperty) -> CABasicAnimation
}

class CABasicAnimationPrototype: AnimationPrototype {
    let delay: CGFloat
    let duration: CGFloat
    let options: UIViewAnimationOptions

    init(delay: CGFloat, duration: CGFloat, options: UIViewAnimationOptions) {
        self.delay = delay
        self.duration = duration
        self.options = options
    }

    func createAnimation(keyPath: AnimationProperty) -> CABasicAnimation {
        return CABasicAnimation(keyPath: keyPath, protoType: self)
    }
}

class CASpringAnimationPrototype: CABasicAnimationPrototype {
    let damping: CGFloat
    let initialSpringVelocity: CGFloat

    init(delay: CGFloat, duration: CGFloat, damping: CGFloat, initialSpringVelocity: CGFloat, options: UIViewAnimationOptions) {
        self.damping = damping
        self.initialSpringVelocity = initialSpringVelocity
        super.init(delay: delay, duration: duration, options: options)
    }

    override func createAnimation(keyPath: AnimationProperty) -> CABasicAnimation {
        return CASpringAnimation(keyPath: keyPath, protoType: self)
    }
}
