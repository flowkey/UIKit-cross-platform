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
        panGestureRecognizer.onStateChanged = onPanGestureStateChanged
        addGestureRecognizer(panGestureRecognizer)
    }

     // returns YES if user isn't dragging (touch up) but scroll view is still moving
//    open var isDecelerating: Bool = false

    var lastOnPanTimestamp: Double = 0
    private func onPan() {
        let translation = panGestureRecognizer.translation(in: self)
        panGestureRecognizer.setTranslation(.zero, in: self)

        let newX = contentOffset.x - translation.x
        let newY = contentOffset.y - translation.y
        let newOffset = CGPoint(
            // XXX: Change this to accommodate `bounce`
            x: min(max(newX, -contentInset.left), contentSize.width + contentInset.right),
            y: min(max(newY, -contentInset.top), contentInset.bottom) // XXX: logically incorrect
        )

        setContentOffset(newOffset, animated: false)
        delegate?.scrollViewDidScroll(self)
    }

    private func onPanGestureStateChanged() {
        switch panGestureRecognizer.state {
        case .began:
            delegate?.scrollViewWillBeginDragging(self)
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

    private func startDecelerating() {
        let decelerationRate = UIScrollViewDecelerationRateNormal * 1000
        let initialVelocity = panGestureRecognizer.velocity(in: self)

        // ToDo: take y also into account
        let animationTime = time(
            initialSpeed: Double(initialVelocity.x),
            finalSpeed: 0,
            acceleration: Double(-decelerationRate)
        )

        let distanceToMove = distance(
            acceleration: Double(decelerationRate),
            time: Double(animationTime),
            initialSpeed: Double(initialVelocity.x)
        )

        let sign = -Double(initialVelocity.x / abs(initialVelocity.x)) // +1 or -1
        let signedDistance = sign * distanceToMove

        let newX = contentOffset.x + CGFloat(signedDistance)
        let newY = contentOffset.y
        let newOffset = CGPoint(
            // XXX: Change this to accommodate `bounce`
            x: min(max(newX, -contentInset.left), contentSize.width + contentInset.right),
            y: min(max(newY, -contentInset.top), contentInset.bottom) // XXX: logically incorrect
        )
        UIView.animate(withDuration: animationTime, options: [.curveEaseOut],  animations: {
            setContentOffset(newOffset, animated: false)
        }, completion: { isCompleted in

        })
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
    }
}

public protocol UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool)
}


fileprivate func time(initialSpeed: Double, finalSpeed: Double, acceleration: Double) -> Double {
    return abs((finalSpeed - initialSpeed) / acceleration)
}

fileprivate func distance(acceleration: Double, time: Double, initialSpeed: Double) -> Double {
    return abs((initialSpeed * time)) + abs((0.5 * acceleration * pow(time, 2)))
}
