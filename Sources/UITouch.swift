//
//  UITouch.swift
//  UIKit
//
//  Created by Geordie Jay on 29.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public class UITouch {
    // using this to convert SDL touches into UIView touches
    internal init(at point: CGPoint, touchId: Int, window: UIWindow = UIWindow.main) {
        absoluteLocation = point
        previousAbsoluteLocation = point
        self.touchId = touchId
        self.window = window
    }

    let touchId: Int

    public weak var view: UIView?
    public weak var window: UIWindow?
    public var gestureRecognizers: [UIGestureRecognizer] = []

    public var phase: UITouchPhase = .began

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

}

public enum UITouchPhase: Int {
    case began, moved, ended
}

extension UITouch: Hashable {
    public var hashValue: Int {
        return touchId
    }

    static public func == (lhs: UITouch, rhs: UITouch) -> Bool {
        return lhs.touchId == rhs.touchId
    }
}
