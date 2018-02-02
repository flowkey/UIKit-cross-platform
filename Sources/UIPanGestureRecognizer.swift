//
//  UIPanGestureRecognizer.swift
//  UIKit
//
//  Created by Geordie Jay on 29.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import Foundation

 // hand-tuned values
private let recentVelocityCount: Int = 10
private let velocityThreshold: CGFloat = 100

open class UIPanGestureRecognizer: UIGestureRecognizer {
    private var initialTouchPoint: CGPoint?

    private var timeSinceLastMovement: TimeInterval?
    private var lastMovementTimestamp: TimeInterval?

    private let minimumTranslationThreshold: CGFloat = 5

    private var recentVelocities = [CGPoint](repeating: .zero, count: recentVelocityCount)
    
        open func translation(in view: UIView?) -> CGPoint {
        guard
            let positionInTargetView = trackedTouch?.location(in: self.view),
            let initialTouchPoint = initialTouchPoint
        else { return .zero }

        return CGPoint(
            x: positionInTargetView.x - initialTouchPoint.x,
            y: positionInTargetView.y - initialTouchPoint.y
        )
    }

    open func setTranslation(_ translation: CGPoint, in view: UIView?) {
        guard let trackedTouch = trackedTouch else { return }
        let positionInTargetView = trackedTouch.location(in: view)
        initialTouchPoint = CGPoint(
            x: positionInTargetView.x - translation.x,
            y: positionInTargetView.y - translation.y
        )
    }

    // The velocity of the pan gesture, which is expressed in points per second.
    // The velocity is broken into horizontal and vertical components.
    open func velocity(in view: UIView?) -> CGPoint {
        guard 
            let lastVelocity = recentVelocities.last,
            lastVelocity.absoluteValue > velocityThreshold
        else { return .zero }

        return recentVelocities.mean()
    }

    private func trackVelocity(in view: UIView?) {
        guard
            let curPos = trackedTouch?.location(in: view),
            let prevPos = trackedTouch?.previousLocation(in: view),
            let timeSinceLastMovement = timeSinceLastMovement,
            timeSinceLastMovement != 0.0
        else {
            return
        }

        // XXX: apple docs say velocity is in points per s (see above)
        // here we use milliseconds though in order to get results in the same magnitude as in iOS
        let timeDiffInMs = CGFloat(timeSinceLastMovement)
        
        recentVelocities.removeFirst()
        recentVelocities.append(CGPoint(
            x: (curPos.x - prevPos.x) / timeDiffInMs,
            y: (curPos.y - prevPos.y) / timeDiffInMs
        ))
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

        trackVelocity(in: nil)

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
        recentVelocities = [CGPoint](repeating: .zero, count: recentVelocityCount)
    }
}

private extension CGPoint {
    var absoluteValue: CGFloat {
        return sqrt(pow(self.x, 2) + pow(self.y, 2))
    }
}
