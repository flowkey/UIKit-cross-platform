//
//  CASpringAnimation.swift
//  UIKit
//
//  Created by Michael Knoch on 08.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

class CASpringAnimation: CABasicAnimation {

    var damping: CGFloat
    var initialSpringVelocity: CGFloat

    init(keyPath: AnimationProperty, protoType: CASpringAnimationPrototype) {
        self.damping = protoType.damping
        self.initialSpringVelocity = protoType.initialSpringVelocity

        super.init(keyPath: keyPath, protoType: protoType)
    }
}
