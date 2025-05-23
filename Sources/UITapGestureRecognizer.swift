//
//  UITapGestureRecognizer.swift
//  UIKit
//
//  Created by Geordie Jay on 30.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

@MainActor
open class UITapGestureRecognizer: UIGestureRecognizer {
    var onTouchesBegan: (() -> Void)?
    var onTouchesEnded: (() -> Void)?
    var onPress: (@MainActor () -> Void)?

    public init(onPress: (@MainActor () -> Void)? = nil) {
        self.onPress = onPress
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        trackedTouch = touches.first
        self.state = .began
        onTouchesBegan?()

        // run potential cancellation of touches in view and other recognizers
        // after `self.state` has been mutated
        if cancelsTouchesInView {
            trackedTouch?.hasBeenCancelledByAGestureRecognizer = true
        }
        cancelOtherGestureRecognizersThatShouldNotRecognizeSimultaneously()
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        if let trackedTouch = trackedTouch, touches.first == trackedTouch {
            let trackedTouchLocationInView = trackedTouch.location(in: view)
            if
                let view = self.view, view.point(inside: trackedTouchLocationInView, with: event),
                self.state == .began
            {
                self.state = .recognized
                onPress?()
                self.state = .possible
            } else {
                self.state = .failed
            }
        }
        onTouchesEnded?()
    }
}
