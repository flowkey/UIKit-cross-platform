//
//  UITapGestureRecognizer.swift
//  UIKit
//
//  Created by Geordie Jay on 30.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

@MainActor
open class UITapGestureRecognizer: UIGestureRecognizer {
    public var numberOfTouchesRequired = 1

    /// How far a finger can move before it's no longer a tap, like iOS's.
    private let allowableMovement: CGFloat = 10

    /// Set by `Button`: like a `UIButton`, it fires on touch up within this distance of its bounds wherever the finger moved.
    internal var touchUpInsideMargin: CGFloat?

    internal var onTouchesBegan: (() -> Void)?
    internal var onTouchesEnded: (() -> Void)?

    private var startLocations: [UITouch: CGPoint] = [:]

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        for touch in touches { startLocations[touch] = touch.location(in: nil) }
        if numberOfTouches > numberOfTouchesRequired { state = .failed; return }
        if numberOfTouches == touches.count { onTouchesBegan?() }
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard touchUpInsideMargin == nil else { return }
        for touch in touches {
            guard let start = startLocations[touch] else { continue }
            if (touch.location(in: nil) - start).magnitude > allowableMovement { state = .failed; return }
        }
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        guard activeTouches.isEmpty, state == .possible else { return }
        guard numberOfTouches == numberOfTouchesRequired else { state = .failed; return }

        if let touchUpInsideMargin, let view, let touch = touches.first {
            let isInside = view.bounds.insetBy(dx: -touchUpInsideMargin, dy: -touchUpInsideMargin).contains(touch.location(in: view))
            state = isInside ? .recognized : .failed
        } else {
            state = .recognized
        }
    }

    open override func reset() {
        super.reset()
        if !startLocations.isEmpty { onTouchesEnded?() }
        startLocations = [:]
    }
}
