//
//  UITapGestureRecognizer.swift
//  UIKit
//
//  Created by Geordie Jay on 30.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class UITapGestureRecognizer: UIGestureRecognizer {
    public typealias OnPressCallback = (() -> Void)
    var onPress: OnPressCallback?

    public init(onPress: OnPressCallback? = nil) {
        self.onPress = onPress
    }

    var trackedTouch: UITouch?

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if !isEnabled { state = .cancelled; return }
        trackedTouch = touches.first
        self.state = .began
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if let trackedTouch = trackedTouch, touches.first == trackedTouch {
            if let view = self.view, view.bounds.contains(trackedTouch.location(in: view)) {
                self.state = .recognized
                onPress?()
                self.state = .possible
            } else {
                self.state = .failed
            }
        }
    }
}
