//
//  UITapGestureRecognizer.swift
//  UIKit
//
//  Created by Geordie Jay on 30.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class UITapGestureRecognizer: UIGestureRecognizer {

    var onTouchesBegan: (() -> Void)?
    var onTouchesEnded: (() -> Void)?
    var onPress: (() -> Void)?

    public init(onPress: (() -> Void)? = nil) {
        self.onPress = onPress
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        trackedTouch = touches.first
        self.state = .began
        onTouchesBegan?()
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        if let trackedTouch = trackedTouch, touches.first == trackedTouch {
            let trackedTouchLocationInView = trackedTouch.location(in: view)
            if let view = self.view, view.point(inside: trackedTouchLocationInView, with: event) {
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
