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

    private let allowableMovement: CGFloat = 10

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
        for touch in touches {
            guard let start = startLocations[touch] else { continue }
            if (touch.location(in: nil) - start).magnitude > allowableMovement { state = .failed; return }
        }
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        guard activeTouches.isEmpty, state == .possible else { return }
        guard numberOfTouches == numberOfTouchesRequired else { state = .failed; return }

        state = .recognized
    }

    open override func reset() {
        super.reset()
        if !startLocations.isEmpty { onTouchesEnded?() }
        startLocations = [:]
    }
}
