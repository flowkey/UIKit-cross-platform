//
//  UITouch.swift
//  UIKit
//
//  Created by Geordie Jay on 29.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import struct Foundation.TimeInterval

public class UITouch {
    public init() {
        absoluteLocation = .zero
        previousAbsoluteLocation = .zero
        timestamp = 0
        touchId = 0
    }

    internal init(touchId: Int, at point: CGPoint, timestamp: TimeInterval) {
        absoluteLocation = point
        previousAbsoluteLocation = point
        self.touchId = touchId
        self.timestamp = timestamp
    }

    internal let touchId: Int

    public weak var view: UIView?
    public weak var window: UIWindow?

    public var phase: UITouchPhase = .began
    public var timestamp: TimeInterval

    private var absoluteLocation: CGPoint
    private var previousAbsoluteLocation: CGPoint

    func updateAbsoluteLocation(_ newLocation: CGPoint) {
        previousAbsoluteLocation = absoluteLocation
        absoluteLocation = newLocation
    }

    public func location(in view: UIView?) -> CGPoint {
        return window?.convert(absoluteLocation, to: view) ?? absoluteLocation
    }

    public func previousLocation(in view: UIView?) -> CGPoint {
        return window?.convert(previousAbsoluteLocation, to: view) ?? previousAbsoluteLocation
    }

    public var gestureRecognizers: [UIGestureRecognizer] = []
    func runTouchActionOnRecognizerHierachy(_ action: (_ recognizer: UIGestureRecognizer) -> Void) {
        for recognizer in gestureRecognizers {
            action(recognizer)
        }
    }
}

extension UITouch: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(touchId)
    }

    public static func == (lhs: UITouch, rhs: UITouch) -> Bool {
        return lhs.touchId == rhs.touchId
    }
}

public enum UITouchPhase: Int {
    case began, moved, ended
}

