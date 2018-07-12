//
//  UIResponder.swift
//  UIKit
//
//  Created by Geordie Jay on 25.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class UIResponder {
    public init() {}
    open weak var next: UIResponder?

    open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        next?.touchesBegan(touches, with: event)
    }

    open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        next?.touchesMoved(touches, with: event)
    }

    open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        next?.touchesEnded(touches, with: event)
    }

    open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        next?.touchesCancelled(touches, with: event)
    }

    /// Returns whether we handled the press or not
    open func handleHardwareBackButtonPress() -> Bool {
        return next?.handleHardwareBackButtonPress() ?? false
    }
}
