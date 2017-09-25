//
//  UIScrollView.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

// values from iOS
let UIScrollViewDecelerationRateFast: CGFloat = 0.99
let UIScrollViewDecelerationRateNormal: CGFloat = 0.998

open class UIScrollView: UIView {
    open var delegate: UIScrollViewDelegate? // TODO: change this to individually settable callbacks
    open var panGestureRecognizer = UIPanGestureRecognizer()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        panGestureRecognizer.onAction = self.onPan
        panGestureRecognizer.onStateChanged = self.onPanGestureStateChanged
        addGestureRecognizer(panGestureRecognizer)
    }

    open var isDecelerating: Bool = false

    private func onPan() {
        let translation = panGestureRecognizer.translation(in: self)
        panGestureRecognizer.setTranslation(.zero, in: self)

        let newOffset = getBoundsCheckedContentOffset(
            x: contentOffset.x - translation.x,
            y: contentOffset.y - translation.y
        )

        setContentOffset(newOffset, animated: false)
    }

    private func onPanGestureStateChanged() {
        switch panGestureRecognizer.state {
        case .began:
            delegate?.scrollViewWillBeginDragging(self)
            cancelDeceleratingIfNeccessary()
        case .ended:
            delegate?.scrollViewDidEndDragging(self, willDecelerate: false) // TODO: fix me
            startDecelerating()

            // XXX: Spring back with animation:
            //case .ended, .cancelled:
            //if contentOffset.x < contentInset.left {
            //    setContentOffset(CGPoint(x: contentInset.left, y: contentOffset.y), animated: true)
            //}
        default: break
        }
    }

    private let maxVelocity = 1200.0 // hand tuned value
    func easedVelocity(_ velocity: Double) -> Double {
        let normalizedVelocity = min(abs(velocity), maxVelocity) / maxVelocity
        let easedVelocity = Double(CAMediaTimingFunction.easeInQuad(CGFloat(normalizedVelocity)))
        let denormalizedVelocity = easedVelocity * maxVelocity
        return denormalizedVelocity
    }

    private func startDecelerating() {
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

    private func cancelDeceleratingIfNeccessary() {
        if !isDecelerating { return }

        UIView.animate(withDuration: 0, animations: {
            let currentX = -(layer.presentation?.bounds.origin.x ?? bounds.origin.x)
            setContentOffset(CGPoint(x: currentX, y: 0), animated: false)
        })
        isDecelerating = false
    }


    // does some min/max checks to prevent newOffset being out of bounds
    private func getBoundsCheckedContentOffset(x: CGFloat, y: CGFloat) -> CGPoint {
        return CGPoint(
            // XXX: Change this to accommodate `bounce`
            x: min(max(x, -contentInset.left), contentSize.width - contentInset.right),
            y: min(max(y, -contentInset.top), contentInset.bottom) // XXX: logically incorrect
        )
    }

    open var contentInset = UIEdgeInsets() //{ didSet {updateBounds()} }
    open var contentSize: CGSize = .zero {
        didSet { bounds.size = contentSize }
    }
    open var contentOffset: CGPoint = .zero { didSet {updateBounds()} }

    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extendedBounds = CGRect(
            x: -contentInset.left,
            y: -contentInset.top,
            width: max(bounds.width, contentInset.left + contentSize.width + contentInset.right),
            height: max(bounds.height, contentInset.top + contentSize.height + contentInset.bottom)
        )

        return extendedBounds.contains(point)
    }

    private func updateBounds() {
        // logically it'd make sense for origin to be `inset + offset` but
        // the original implementation seems to do what we have here instead:
        bounds.origin = -contentOffset
    }

    // TODO: Implement these:
    open var showsVerticalScrollIndicator = true
    open var showsHorizontalScrollIndicator = true

    open func setContentOffset(_ point: CGPoint, animated: Bool) {
        // TODO: animate
        contentOffset = point
        delegate?.scrollViewDidScroll(self)
    }
}

public protocol UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool)
}

fileprivate func time(initialVelocity: Double, accleration: Double, distance: Double) -> Double {
    let term1 = -(initialVelocity / accleration)
    let term2 = sqrt( pow((initialVelocity / accleration), 2) + (2 * distance / accleration) )

    let t1 = term1 + term2
    let t2 = term1 - term2

    return min(abs(t1), abs(t2))
}

fileprivate func time(initialVelocity: Double, acceleration: Double, finalVelocity: Double) -> Double {
    return abs((finalVelocity - initialVelocity) / acceleration)
}

fileprivate func distance(acceleration: Double, time: Double, initialVelocity: Double) -> Double {
    return abs((initialVelocity * time)) + abs((0.5 * acceleration * pow(time, 2)))
}
