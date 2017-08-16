//
//  CASpringAnimation.swift
//  UIKit
//
//  Created by Michael Knoch on 08.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import Foundation

class CASpringAnimation: CABasicAnimation {
    var damping: CGFloat
    var initialSpringVelocity: CGFloat
    let spring: (Double) -> Double

    init(keyPath: AnimationProperty, protoType: CASpringAnimationPrototype) {
        self.damping = protoType.damping
        self.initialSpringVelocity = protoType.initialSpringVelocity
        self.spring = springFactory(cycles: 3, damping: Double(damping), initialPosition: 1, initialVelocity: Double(initialSpringVelocity))

        super.init(keyPath: keyPath, protoType: protoType)
    }

    override func x(at timer: Timer) -> CGFloat {
        let fraction = Double(progress(at: timer))
        return CGFloat(spring(fraction))
    }
}


fileprivate func springFactory
(cycles: Int, damping: Double, initialPosition: Double, initialVelocity: Double) -> (Double) -> Double {

    let A = initialPosition
    let B = initialVelocity
    let zeta = damping
    let omega = Double(cycles)

    let springEasing: (Double) -> Double = { fractionCompleted in
        let x = 2 * .pi * omega * fractionCompleted
        let x_damped = sqrt(1 - pow(zeta, 2)) * x

        return exp(-zeta * x) * (A * cos(x_damped) + B * sin(x_damped))
    }

    return springEasing
}

