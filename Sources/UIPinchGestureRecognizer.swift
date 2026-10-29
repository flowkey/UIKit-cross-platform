//
//  UIPinchGestureRecognizer.swift
//  UIKit
//
//  Created by Chris on 28.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public class UIPinchGestureRecognizer: UIGestureRecognizer {
    /// Relative to the distance between the fingers when the pinch began, or when `scale` was last set.
    public var scale: CGFloat {
        get {
            guard let distance = currentDistance, let referenceDistance, referenceDistance > 0 else { return referenceScale }
            return referenceScale * distance / referenceDistance
        }
        set {
            referenceScale = newValue
            referenceDistance = currentDistance
        }
    }

    /// How much the distance between the fingers changes before the pinch begins.
    private let hysteresis: CGFloat = 4

    private var referenceScale: CGFloat = 1
    private var referenceDistance: CGFloat?

    private var currentDistance: CGFloat? {
        let activeTouches = activeTouches
        guard activeTouches.count == 2 else { return nil }
        return (activeTouches[0].location(in: nil) - activeTouches[1].location(in: nil)).magnitude
    }

    override var canTrackAnotherTouch: Bool {
        activeTouches.count < 2
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        if referenceDistance == nil { referenceDistance = currentDistance }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard let distance = currentDistance else { return }
        switch state {
        case .possible:
            guard let referenceDistance, abs(distance - referenceDistance) >= hysteresis else { return }
            state = .began
        case .began, .changed:
            state = .changed
        case .ended, .cancelled, .failed:
            break
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        guard state == .began || state == .changed else { return }
        state = .ended
    }

    public override func reset() {
        super.reset()
        referenceScale = 1
        referenceDistance = nil
    }
}
