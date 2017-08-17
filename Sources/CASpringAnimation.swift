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
        self.spring = springFactory(halfCycles: 6, damping: Double(damping), initialPosition: 1, initialVelocity: Double(initialSpringVelocity))

        super.init(keyPath: keyPath, protoType: protoType)
    }

    override func compute(at timer: Timer) -> CGFloat {
        let fraction = Double(updateProgress(to: timer))
        return CGFloat(spring(fraction))
    }
}

//
//fileprivate func springFactory
//(cycles: Double, damping: Double, initialPosition: Double, initialVelocity: Double) -> (Double) -> Double {
//
//    let A = initialPosition
//    let B = initialVelocity
//    let zeta = damping
//
//    let k = cycles
//    let omega = (-tan(A/B) + .pi * k) / (2 * .pi * sqrt(1 - pow(zeta, 2)))
//
//    return { fractionCompleted in
//        let arg1 = 2 * .pi * omega * fractionCompleted
//        let arg2 = sqrt(1 - pow(zeta, 2)) * arg1
//
//        return exp(-zeta * arg1) * (A * cos(arg2) + B * sin(arg2))
//    }
//}


fileprivate func springFactory
(halfCycles: Int, damping: Double, initialPosition: Double, initialVelocity: Double) -> (Double) -> Double {
    let A = initialPosition
    var B = initialVelocity
    var omega = 0.0

//    if initialVelocity == 0.0 {
    B = damping * A / sqrt(1 - pow(damping, 2))
    omega = (-tan(A/B) + .pi * Double(halfCycles)) / (2 * .pi * sqrt(1 - pow(damping, 2))) * 2 * .pi
//    } else { /* ToDo: numerically solve omega */ }

    let omega_d = omega * sqrt(1 - pow(damping, 2))

    return { t in // t: 0..1
        return exp(-damping * omega * t) * (A * cos(omega_d * t) + B * sin(omega_d * t))
    }
}

