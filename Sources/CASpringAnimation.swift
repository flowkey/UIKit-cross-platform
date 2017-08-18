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

    init(
        duration: CGFloat,
        delay: CGFloat,
        damping: CGFloat,
        initialSpringVelocity: CGFloat,
        options: UIViewAnimationOptions
    ) {
        self.damping = damping
        self.initialSpringVelocity = initialSpringVelocity
        super.init(duration: duration, delay: delay, options: options)
    }
}

extension CASpringAnimation {
    convenience init(from animation: CASpringAnimation) {
        self.init(
            duration: animation.duration,
            delay: animation.delay,
            damping: animation.damping,
            initialSpringVelocity: animation.initialSpringVelocity,
            options: animation.options
        )

        damping = animation.damping
        initialSpringVelocity = animation.initialSpringVelocity
    }
}
