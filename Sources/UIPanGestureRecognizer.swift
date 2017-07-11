//
//  UIPanGestureRecognizer.swift
//  UIKit
//
//  Created by Geordie Jay on 29.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class UIPanGestureRecognizer: UIGestureRecognizer {
    internal var onPan: OnPanCallback
    public typealias OnPanCallback = (() -> Void)?
    public init(onPan: OnPanCallback = nil) {
        self.onPan = onPan
    }

    private var initialTouchPoint: CGPoint = .zero // should probably be optional instead
    private var trackedTouch: UITouch?

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

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let firstTouch = touches.first else { return }
        state = .began
        trackedTouch = firstTouch
        initialTouchPoint = firstTouch.location(in: self.view)
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let trackedTouch = trackedTouch, touches.first == trackedTouch else {
            state = .failed
            return
        }

        let currentLocation = trackedTouch.location(in: self.view)

        if
            state == .began,
            (currentLocation.x - initialTouchPoint.x).magnitude >= minimumTranslationThreshold ||
            (currentLocation.y - initialTouchPoint.y).magnitude >= minimumTranslationThreshold
        {
            // Activate:
            state = .changed
        }

        if state == .changed {
            onPan?()
        }
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let trackedTouch = trackedTouch, touches.contains(trackedTouch) else { return }
        state = .ended
        reset()
    }

    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        reset()
    }

    private func reset() {
        self.trackedTouch = nil
        initialTouchPoint = .zero
        state = .possible
    }
}
