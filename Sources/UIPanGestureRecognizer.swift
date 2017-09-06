//
//  UIPanGestureRecognizer.swift
//  UIKit
//
//  Created by Geordie Jay on 29.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import Foundation

open class UIPanGestureRecognizer: UIGestureRecognizer {
    private var initialTouchPoint: CGPoint = .zero // should probably be optional instead

    private var lastLocation: CGPoint?
    private var currentLocation: CGPoint?

    private var trackedTouch: UITouch?

    private var timeSinceLastMovement: TimeInterval?
    private var lastMovementTime: TimeInterval?

    private let minimumTranslationThreshold: CGFloat = 5

    open func translation(in view: UIView?) -> CGPoint {
        guard let trackedTouch = trackedTouch else { return .zero }
        let currentPosition = trackedTouch.location(in: self.view)
        let point = CGPoint(x: currentPosition.x - initialTouchPoint.x, y: currentPosition.y - initialTouchPoint.y)
        return self.view?.convert(point, to: view) ?? point
    }

    open func setTranslation(_ point: CGPoint, in view: UIView?) {
        guard let trackedTouch = trackedTouch else { return }
        let positionInTargetView = trackedTouch.location(in: view)
        initialTouchPoint = CGPoint(x: positionInTargetView.x + point.x, y: positionInTargetView.y + point.y)
    }

    // The velocity of the pan gesture, which is expressed in points per second.
    // The velocity is broken into horizontal and vertical components.
    open func velocity(in view: UIView?) -> CGPoint {

        guard let curPos = currentLocation, let lastPos = lastLocation else {
            print("no current or last location")
            return CGPoint.zero
        }

        guard let timeSinceLastMovement = timeSinceLastMovement, timeSinceLastMovement != 0.0 else {
            print("no timeSinceLastMovement or timeSinceLastMovement is 0")
            return CGPoint.zero
        }

        let timeDiffInMs = CGFloat(timeSinceLastMovement)
        // XXX: apple docs say velocity is in points per s (see above)
        // here we use ms in order to get results in the same magnitude as in iOS though

        return CGPoint(
            x: (curPos.x - lastPos.x) / timeDiffInMs,
            y: (curPos.y - lastPos.y) / timeDiffInMs
        )
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        guard let firstTouch = touches.first else { return }
        state = .began
        trackedTouch = firstTouch
        initialTouchPoint = firstTouch.location(in: self.view)
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard let trackedTouch = trackedTouch, touches.first == trackedTouch else {
            state = .failed
            return
        }

        lastLocation = currentLocation
        currentLocation = trackedTouch.location(in: self.view)

        // XXX: revisit this and decide which timer we want to use
        let now = NSDate.timeIntervalSinceReferenceDate
        timeSinceLastMovement = now - lastMovementTime // optional substraction, see "-" operator for TimeInterval? below
        lastMovementTime = now

        if  state == .began,
            let location = currentLocation,
            (location.x - initialTouchPoint.x).magnitude >= minimumTranslationThreshold ||
            (location.y - initialTouchPoint.y).magnitude >= minimumTranslationThreshold
        {
            // Activate:
            state = .changed
        }

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
        reset()
    }

    private func reset() {
        trackedTouch = nil
        currentLocation = nil
        lastLocation = nil
        lastMovementTime = nil
        timeSinceLastMovement = nil
        initialTouchPoint = .zero
        state = .possible
    }
}

fileprivate func -(left: TimeInterval?, right: TimeInterval?) -> TimeInterval? {
    guard let lhs = left, let rhs = right else { return nil }
    return lhs - rhs
}
