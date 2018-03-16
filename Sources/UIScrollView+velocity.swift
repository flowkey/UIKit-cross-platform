//
//  UIScrollView+velocity.swift
//  UIKit
//
//  Created by flowing erik on 25.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import func Foundation.sqrt

private extension CGPoint {
    var magnitude: CGFloat {
        return sqrt(x * x + y * y)
    }
}

extension UIScrollView {
    func startDeceleratingIfNecessary() {
        // Only animate if instantaneous velocity is large enough
        // Otherwise we could animate after scrolling quickly, pausing for a few seconds, then letting go
        let willDecelerate = (self.panGestureRecognizer.velocity(in: self).magnitude >= 20)
        delegate?.scrollViewDidEndDragging(self, willDecelerate: willDecelerate)
        guard willDecelerate else { return }

        let nonBoundsCheckedScrollAnimationDistance = self.currentVelocity * 0.74 // hand-tuned to match easing curve

        let targetOffset = getBoundsCheckedContentOffset(contentOffset - nonBoundsCheckedScrollAnimationDistance)
        let distanceToBoundsCheckedTarget = contentOffset - targetOffset

        // The 325 should be calculated from `UIScrollViewDecelerationRateXYZ` instead:
        // This calculation is a weird approximation but it's close enough for now...
        let animationTime = log(Double(distanceToBoundsCheckedTarget.magnitude)) * 325 / 1000 / 2

        UIView.animate(withDuration: animationTime, options: [.beginFromCurrentState, .customEaseOut, .allowUserInteraction],  animations: {
            self.isDecelerating = true
            self.contentOffset = targetOffset
        }, completion: { _ in
            self.isDecelerating = false
        })
    }

    func cancelDeceleratingIfNeccessary() {
        if !isDecelerating { return }

        let currentOrigin = layer.presentation?.bounds.origin ?? bounds.origin
        setContentOffset(currentOrigin, animated: false)
        layer.removeAnimation(forKey: "bounds")

        isDecelerating = false
    }
}
