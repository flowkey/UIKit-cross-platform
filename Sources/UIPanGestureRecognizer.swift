//
//  UIPanGestureRecognizer.swift
//  UIKit
//
//  Created by Geordie Jay on 29.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import Foundation

 // hand-tuned values
private let velocityThreshold: CGFloat = 100
private let velocityBuffersize: Int = 10

open class UIPanGestureRecognizer: UIGestureRecognizer {
    private var initialTouchPoint: CGPoint?

    private var lastMovementTimestamp: TimeInterval?
    private var timeSinceLastMovement: TimeInterval?

    private let minimumTranslationThreshold: CGFloat = 5

    private let velocityTracker = VelocityTracker(bufferSize: velocityBuffersize)
    
    open func translation(in view: UIView?) -> CGPoint {
        guard
            let positionInTargetView = trackedTouch?.location(in: self.view),
            let initialTouchPoint = initialTouchPoint
        else { return .zero }

        return positionInTargetView - initialTouchPoint
    }

    open func setTranslation(_ translation: CGPoint, in view: UIView?) {
        guard let trackedTouch = trackedTouch else { return }
        let positionInTargetView = trackedTouch.location(in: view)
        initialTouchPoint = positionInTargetView - translation
    }

    // The velocity of the pan gesture, which is expressed in points per second.
    // The velocity is broken into horizontal and vertical components.
    open func velocity(in view: UIView?) -> CGPoint {
        if velocityTracker.last.normLength < velocityThreshold {
            return .zero
        }

        return velocityTracker.mean
    }

    private func trackVelocity(in view: UIView?, for timeSinceLastMovement: TimeInterval) {
        guard
            let curPos = trackedTouch?.location(in: view),
            let prevPos = trackedTouch?.previousLocation(in: view),
            timeSinceLastMovement != 0.0
        else {
            return
        }

        velocityTracker.track(
            timeInterval: timeSinceLastMovement,
            previousPoint: prevPos,
            currentPoint: curPos
        )
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        guard let firstTouch = touches.first else { return }
        state = .began
        trackedTouch = firstTouch
        initialTouchPoint = firstTouch.location(in: self.view?.superview)
        lastMovementTimestamp = NSDate.timeIntervalSinceReferenceDate
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard
            let trackedTouch = trackedTouch,
            touches.first == trackedTouch,
            let initialTouchPoint = initialTouchPoint
        else {
            state = .failed
            return
        }

        // XXX: revisit this and decide which timer we want to use
        let now = NSDate.timeIntervalSinceReferenceDate

        if let before = lastMovementTimestamp {
            timeSinceLastMovement = now - before
        }
        lastMovementTimestamp = now

        let location = trackedTouch.location(in: self.view?.superview)

        if  state == .began,
            (location.x - initialTouchPoint.x).magnitude >= minimumTranslationThreshold ||
            (location.y - initialTouchPoint.y).magnitude >= minimumTranslationThreshold
        {
            // Activate:
            state = .changed
        }

        trackVelocity(in: self.view, for: timeSinceLastMovement ?? 0)

        if state == .changed {
            onAction?()
        }
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        guard let trackedTouch = trackedTouch, touches.contains(trackedTouch) else { return }
        state = .ended
        reset()
    }

    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        state = .cancelled
        reset()
    }

    private func reset() {
        trackedTouch = nil
        lastMovementTimestamp = nil
        timeSinceLastMovement = nil
        initialTouchPoint = .zero
        state = .possible
        velocityTracker.reset()
    }
}
