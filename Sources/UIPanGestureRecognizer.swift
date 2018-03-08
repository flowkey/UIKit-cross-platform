//
//  UIPanGestureRecognizer.swift
//  UIKit
//
//  Created by Geordie Jay on 29.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import Foundation

open class UIPanGestureRecognizer: UIGestureRecognizer {
    private var initialTouchPoint: CGPoint?

    private var lastMovementTimestamp: TimeInterval?
    private var timeSinceLastMovement: TimeInterval?

    private let minimumTranslationThreshold: CGFloat = 5

    open func translation(in view: UIView?) -> CGPoint {
        guard
            let trackedTouch = trackedTouch,
            let initialTouchPoint = initialTouchPoint
        else { return .zero }

        let positionInTargetView = trackedTouch.location(in: view)
        return (positionInTargetView - initialTouchPoint)
            // if positionInTargetView and initialTouchPoint would be converted correctly
            // this wouldnt be neccesary. TODO: fix slow path in UIView.convert
            .applying(view?.superview?.transform.inverted() ?? .identity)
    }

    open func setTranslation(_ translation: CGPoint, in view: UIView?) {
        guard let trackedTouch = trackedTouch else { return }
        let positionInTargetView = trackedTouch.location(in: view)
        initialTouchPoint = positionInTargetView - translation
    }

    // The velocity of the pan gesture, which is expressed in points per second.
    // The velocity is broken into horizontal and vertical components.
    func velocity(in view: UIView?) -> CGPoint {
        guard
            let curPos = trackedTouch?.location(in: view),
            let prevPos = trackedTouch?.previousLocation(in: view),
            let timeSinceLastMovement = self.timeSinceLastMovement,
            timeSinceLastMovement != 0.0
        else { return CGPoint.zero }

        // XXX: apple docs say velocity is in points per s (see above)
        // here we use timeSinceLastMovement in milliseconds though 
        // in order to get results in the same magnitude as in iOS
        return (curPos - prevPos) / CGFloat(timeSinceLastMovement)
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
    }
}
