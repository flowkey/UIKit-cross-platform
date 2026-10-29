//
//  UIScrollView+velocity.swift
//  UIKit
//
//  Created by flowing erik on 25.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension UIScrollView {
    func startDeceleratingIfNecessary() {
        // Only animate if instantaneous velocity is large enough
        // Otherwise we could animate after scrolling quickly, pausing for a few seconds, then letting go
        let velocityIsLargeEnoughToDecelerate = (self.panGestureRecognizer.velocity(in: self).magnitude > 10)

        let dampingFactor = 0.5 // hand-tuned
        let nonBoundsCheckedScrollAnimationDistance = self.weightedAverageVelocity * CGFloat(dampingFactor) // hand-tuned
        let targetOffset = getBoundsCheckedContentOffset(contentOffset - nonBoundsCheckedScrollAnimationDistance)
        let distanceToBoundsCheckedTarget = contentOffset - targetOffset

        // Under a point, `animationTime` below would be negative.
        let willDecelerate = (velocityIsLargeEnoughToDecelerate && distanceToBoundsCheckedTarget.magnitude > 1)
        delegate?.scrollViewDidEndDragging(self, willDecelerate: willDecelerate)
        guard willDecelerate else { hideScrollIndicators(); return }

        // https://ariya.io/2011/10/flick-list-with-its-momentum-scrolling-and-deceleration
        // TODO: This value should be calculated from `self.decelerationRate` instead
        // But actually we want to redo this function to avoid `UIView.animate` entirely,
        // in which case we wouldn't need an animationTime at all.
        let animationTimeConstant = 0.325 * dampingFactor

        // This calculation is a weird approximation but it's close enough for now...
        let animationTime = log(Double(distanceToBoundsCheckedTarget.magnitude)) * animationTimeConstant

        UIView.animate(
            withDuration: animationTime,
            options: [.beginFromCurrentState, .customEaseOut, .allowUserInteraction],
            animations: {
                self.isDecelerating = true
                self.contentOffset = targetOffset
            },
            completion: { finished in
                self.isDecelerating = false
                if finished { self.delegate?.scrollViewDidEndDecelerating(self) }
            }
        )
    }

    func cancelDeceleratingIfNeccessary() {
        if !isDecelerating { return }

        // Get the presentation value from the current animation
        setContentOffset(visibleContentOffset, animated: false)
        cancelDecelerationAnimations()
        isDecelerating = false
    }

    func cancelDecelerationAnimations() {
        if !layer.animations.isEmpty {
            layer.removeAnimation(forKey: "bounds")
            horizontalScrollIndicator.layer.removeAnimation(forKey: "position")
            verticalScrollIndicator.layer.removeAnimation(forKey: "position")
        }
    }
}
