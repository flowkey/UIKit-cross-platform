//
//  UIPanGestureRecognizer.swift
//  UIKit
//
//  Created by Geordie Jay on 29.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class UIPanGestureRecognizer: UIGestureRecognizer {
    private var initialTouchPoint: CGPoint?

    private var previousTouchesMovedTimestamp: Double?
    private var touchesMovedTimestamp: Double?

    private let minimumTranslationThreshold: CGFloat = 5

    open func translation(in view: UIView?) -> CGPoint {
        guard
            let trackedTouch = trackedTouch,
            let initialTouchPoint = initialTouchPoint
        else { return .zero }

        let positionInTargetView = trackedTouch.location(in: view)
        let initialPositionInTargetView = view?.convert(initialTouchPoint, from: trackedTouch.window)
            ?? initialTouchPoint

        return positionInTargetView - initialPositionInTargetView
    }

    open func setTranslation(_ translation: CGPoint, in view: UIView?) {
        guard let trackedTouch = trackedTouch else { return }
        let positionInTargetView = trackedTouch.location(in: nil)
        initialTouchPoint = positionInTargetView - translation
    }

    // The velocity of the pan gesture, which is expressed in points per second.
    // The velocity is broken into horizontal and vertical components.
    func velocity(in view: UIView?, timeDiffSeconds: Double) -> CGPoint {
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
        self.trackedTouch = trackedTouch
        initialTouchPoint = trackedTouch.location(in: nil)
        touchesMovedTimestamp = trackedTouch.timestamp
        state = .began
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

            // run potential cancellation of touches in view and other recognizers
            // after state has been mutated
            if cancelsTouchesInView {
                trackedTouch.hasBeenCancelledByAGestureRecognizer = true
            }
            cancelOtherGestureRecognizersThatShouldNotRecognizeSimultaneously()
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

    private func reset() {
        trackedTouch = nil
        previousTouchesMovedTimestamp = nil
        touchesMovedTimestamp = nil
        initialTouchPoint = .zero
    }
}
