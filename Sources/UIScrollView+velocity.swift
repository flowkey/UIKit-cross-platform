//
//  UIScrollView+velocity.swift
//  UIKit
//
//  Created by flowing erik on 25.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension UIScrollView {

    fileprivate static let maxVelocity = 1200.0 // hand tuned value

    // fine tuning of initial velocity with an easing curve
    fileprivate func easedVelocity(_ velocity: Double) -> Double {
        let normalizedVelocity = min(abs(velocity), UIScrollView.maxVelocity) / UIScrollView.maxVelocity
        let easedVelocity = Double(CAMediaTimingFunction.easeInQuad(CGFloat(normalizedVelocity)))
        let denormalizedVelocity = easedVelocity * UIScrollView.maxVelocity
        return denormalizedVelocity
    }

    func startDecelerating() {
        let decelerationRate = UIScrollViewDecelerationRateNormal * 1000

        // ToDo: take y also into account
        let gestureVelocity = Double(panGestureRecognizer.velocity(in: self).x)
        if gestureVelocity == 0 { return }

        let initialVelocity = easedVelocity(gestureVelocity)

        // calculate time it would take until deceleration is complete (final velocity = 0)
        var animationTime = time(
            initialVelocity: initialVelocity,
            acceleration: Double(-decelerationRate),
            finalVelocity: 0
        )

        // calculate the distance to move until completely decelerated
        let distanceToMove = distance(
            acceleration: Double(-decelerationRate),
            time: Double(animationTime),
            initialVelocity: initialVelocity
        )

        // determine scroll direction
        let distanceWithDirection = gestureVelocity.sign == .minus ? distanceToMove : -distanceToMove

        var newOffset = CGPoint(
            x: contentOffset.x + CGFloat(distanceWithDirection),
            y: contentOffset.y
        )

        let boundsCheckedOffset = getBoundsCheckedContentOffset(
            x: contentOffset.x + CGFloat(distanceWithDirection),
            y: contentOffset.y
        )

        let offsetIsOutOfBounds = (newOffset != boundsCheckedOffset)
        if offsetIsOutOfBounds {
            newOffset = boundsCheckedOffset
            // time it takes until reaching bounds from current position
            animationTime = time(
                initialVelocity: initialVelocity,
                accleration: Double(decelerationRate),
                distance: Double(abs(contentOffset.x - boundsCheckedOffset.x))
            )
        }

        UIView.animate(withDuration: animationTime, options: [.curveEaseOut, .allowUserInteraction],  animations: {
            self.isDecelerating = true
            self.setContentOffset(newOffset, animated: false)
        }, completion: { _ in
            self.isDecelerating = false
        })
    }

    func cancelDeceleratingIfNeccessary() {
        if !isDecelerating { return }
        layer.removeAnimation(forKey: "bounds")
        isDecelerating = false
    }
}

// MARK: Physics

/// calculate time it takes to accelerate from initialVelocity to finalVelocity
fileprivate func time(initialVelocity: Double, acceleration: Double, finalVelocity: Double) -> Double {
    return abs((finalVelocity - initialVelocity) / acceleration)
}

/// calculate the distance travelled within a time interval after accelerating from initialVelcotity
fileprivate func distance(acceleration: Double, time: Double, initialVelocity: Double) -> Double {
    return abs((initialVelocity * time)) + abs((0.5 * acceleration * pow(time, 2)))
}

/// calculate the time it takes do travel a certain distance given initial velocity and acceleration
/// solution for quadratic equation s = 1/2*a*t^2 + v_0 * t
fileprivate func time(initialVelocity: Double, accleration: Double, distance: Double) -> Double {
    let term1 = -(initialVelocity / accleration)
    let term2 = sqrt( pow((initialVelocity / accleration), 2) + (2 * distance / accleration) )

    let t1 = term1 + term2
    let t2 = term1 - term2

    return min(abs(t1), abs(t2))
}
