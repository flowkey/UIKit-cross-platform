//
//  UIGestureRecognizer.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public enum UIGestureRecognizerState {
    case possible
    case began
    case recognized
    case changed
    case ended
    case cancelled
    case failed
}

// Reference: https://developer.apple.com/library/content/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/ImplementingaCustomGestureRecognizer.html#//apple_ref/doc/uid/TP40009541-CH8-SW1

open class UIGestureRecognizer {
    public var minimumNumberOfTouches = 0
    public var maximumNumberOfTouches = 0
    public var isEnabled = true {
        didSet { if !isEnabled { state = .cancelled } }
    }
    public var delegate: UIGestureRecognizerDelegate?
    public var state: UIGestureRecognizerState = .possible {
        didSet {
            if state == oldValue { return }
            onStateChanged?()
            switch state {
            case .failed, .cancelled:
                // touchesCancelled(touches: Set<UITouch>, with: UIEvent)
                state = .possible
            case .recognized, .ended:
                state = .possible
            default: break
            }
        }
    }
    public var onStateChanged: (() -> Void)? = nil

    public typealias OnActionCallback = (() -> Void)?
    internal var onAction: OnActionCallback

    public init(onAction: OnActionCallback = nil) {
        self.onAction = onAction
    }

    public func require(toFail other: UIGestureRecognizer) {
        // TODO: Not implemented
    }

    weak public var view: UIView?
    public var cancelsTouchesInView = true
    public var delaysTouchesBegan = false
    public var delaysTouchesEnded = true

    open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if !isEnabled { state = .cancelled; return }
    }
    open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {}
    open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {}

    // Cancelled arrives when the in-flight gesture
    open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {}
}

// Allow UIGestureRecognizers to be added to a `Set` etc.
extension UIGestureRecognizer: Hashable {
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }

    public static func == (lhs: UIGestureRecognizer, rhs: UIGestureRecognizer) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
