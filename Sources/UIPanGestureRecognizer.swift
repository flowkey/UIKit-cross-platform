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

    // TODO: make an extension in tests instead of changing this to internal from private
    internal var previousTouchesMovedTimestamp: TimeInterval?
    internal var touchesMovedTimestamp: TimeInterval?

    private let minimumTranslationThreshold: CGFloat = 5

    open func translation(in view: UIView?) -> CGPoint {
        guard
            let trackedTouch = trackedTouch,
            let initialTouchPoint = initialTouchPoint
        else { return .zero }

        let positionInTargetView = trackedTouch.location(in: view)
        let initialPositionInTargetView = view?.convert(initialTouchPoint, from: trackedTouch.window)
            ?? initialTouchPoint

        return (positionInTargetView - initialPositionInTargetView)
            // if positionInTargetView and initialTouchPoint would be converted correctly
            // this wouldnt be neccesary. TODO: fix slow path in UIView.convert
            .applying(view?.superview?.transform.inverted() ?? .identity)
    }

    open func setTranslation(_ translation: CGPoint, in view: UIView?) {
        guard let trackedTouch = trackedTouch else { return }
        let positionInTargetView = trackedTouch.location(in: nil)
        initialTouchPoint = positionInTargetView - translation
    }

    // The velocity of the pan gesture, which is expressed in points per second.
    // The velocity is broken into horizontal and vertical components.
    func velocity(in view: UIView?, timeDiffSeconds: TimeInterval) -> CGPoint {
        guard
            let curPos = trackedTouch?.location(in: view),
            let prevPos = trackedTouch?.previousLocation(in: view),
            timeDiffSeconds.isZero == false
        else { return CGPoint.zero }

        return (curPos - prevPos) / CGFloat(timeDiffSeconds)
    }

    open func velocity(in view: UIView?) -> CGPoint {
        guard
            let touchesMovedTimestamp = touchesMovedTimestamp,
            let previousTouchesMovedTimestamp = previousTouchesMovedTimestamp
        else { return CGPoint.zero }
        
        let timeDiffSeconds = touchesMovedTimestamp - previousTouchesMovedTimestamp
        return velocity(in: view, timeDiffSeconds: timeDiffSeconds)
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        guard let trackedTouch = touches.first else { return }
        state = .began
        self.trackedTouch = trackedTouch
        initialTouchPoint = trackedTouch.location(in: nil)
        touchesMovedTimestamp = trackedTouch.timestamp
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

        let location = trackedTouch.location(in: nil)

        self.previousTouchesMovedTimestamp = touchesMovedTimestamp ?? 0
        self.touchesMovedTimestamp = trackedTouch.timestamp

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
        self.previousTouchesMovedTimestamp = touchesMovedTimestamp ?? 0
        self.touchesMovedTimestamp = trackedTouch.timestamp
        state = .ended
        reset()
    }

    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        reset()
    }

    private func reset() {
        trackedTouch = nil
        previousTouchesMovedTimestamp = nil
        touchesMovedTimestamp = nil
        initialTouchPoint = .zero
        state = .possible
    }
}
