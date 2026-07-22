//
//  UIPinchGestureRecognizer.swift
//  UIKit
//
//  Created by Chris on 28.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public class UIPinchGestureRecognizer: UIGestureRecognizer {
    /// Incremental scale since the last `.changed`, matching iOS (which resets it in the action handler).
    public var scale: CGFloat = 1

    private var previousDistance: CGFloat?

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        guard let distance = Self.distance(between: event.allTouches) else { return }
        // Track a finger that owns a recognizer hierarchy, so cancellation can reach the pan to cancel it.
        trackedTouch = event.allTouches?.first(where: { !$0.gestureRecognizers.isEmpty }) ?? touches.first
        previousDistance = distance
        scale = 1
        state = .began
        cancelOtherGestureRecognizersThatShouldNotRecognizeSimultaneously()
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard
            let previousDistance, previousDistance > 0,
            let distance = Self.distance(between: event.allTouches), distance > 0
        else { return }
        scale = distance / previousDistance
        self.previousDistance = distance
        state = .changed
        onAction?()
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        guard previousDistance != nil else { return } // wasn't pinching
        previousDistance = nil
        scale = 1
        trackedTouch = nil
        state = .ended
    }

    private static func distance(between touches: Set<UITouch>?) -> CGFloat? {
        guard let locations = touches?.map({ $0.location(in: nil) }), locations.count >= 2 else { return nil }
        let dx = locations[0].x - locations[1].x
        let dy = locations[0].y - locations[1].y
        return (dx * dx + dy * dy).squareRoot()
    }
}
