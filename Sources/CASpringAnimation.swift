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
        // number of halfCycles to animate is hard coded, we should figure out how this is behaving in original UIKit
        self.spring = springFactory(halfCycles: 2, damping: Double(damping), initialPosition: 1, initialVelocity: Double(initialSpringVelocity))

        super.init(keyPath: keyPath, protoType: protoType)
    }

    override func compute(at timer: Timer) -> CGFloat {
        let fraction = Double(updateProgress(to: timer))
        return CGFloat(spring(fraction))
    }
}

// https://medium.com/analytic-animations/the-spring-factory-4c3d988e7129
fileprivate func springFactory
(halfCycles: Int, damping: Double, initialPosition: Double, initialVelocity: Double) -> (Double) -> Double {
    let A = initialPosition
    var B = initialVelocity
    var omega = 0.0

//    if initialVelocity == 0.0 {
    B = damping * A / sqrt(1 - pow(damping, 2))
    omega = (-tan(A/B) + .pi * Double(halfCycles)) / (2 * .pi * sqrt(1 - pow(damping, 2))) * 2 * .pi
//    } else { /* ToDo: numerically solve B, then omega */ }

    let omega_d = omega * sqrt(1 - pow(damping, 2))

    return { t in // t: 0..1
        return exp(-damping * omega * t) * (A * cos(omega_d * t) + B * sin(omega_d * t))
    }
}

