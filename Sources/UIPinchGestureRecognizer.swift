//
//  UIPinchGestureRecognizer.swift
//  UIKit
//
//  Created by Chris on 28.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public class UIPinchGestureRecognizer: UIGestureRecognizer {
    /// Incremental scale factor since the last `.changed` callback (iOS resets it in its action handler).
    public var scale: CGFloat = 1

    private var previousDistance: CGFloat?

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        // A pinch needs two fingers; begins only once the second one lands.
        guard let distance = Self.distance(between: event.allTouches) else { return }
        // Track the finger that carries the recognizer hierarchy so simultaneous-recognition coordination
        // can find the other recognizers (e.g. the scroll pan) on it.
        trackedTouch = event.allTouches?.first(where: { !$0.gestureRecognizers.isEmpty }) ?? touches.first
        previousDistance = distance
        scale = 1
        state = .began
        // Recognizing runs the same simultaneous-recognition/cancellation coordination the other recognizers
        // use, so the scroll view's pan is handled via its delegate (GestureOverlay) rather than by hand.
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
