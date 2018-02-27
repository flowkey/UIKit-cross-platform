//
//  UITouch.swift
//  UIKit
//
//  Created by Geordie Jay on 29.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public class UITouch {
    // using this to convert SDL touches into UIView touches
    internal init(at point: CGPoint, touchId: Int) {
        absoluteLocation = point
        previousAbsoluteLocation = point
        self.touchId = touchId
    }

    var touchId: Int
    internal(set) public weak var view: UIView?
    public var gestureRecognizers: [UIGestureRecognizer] = []

    private var absoluteLocation: CGPoint
    private var previousAbsoluteLocation: CGPoint

    func updateAbsoluteLocation(_ newLocation: CGPoint) {
        previousAbsoluteLocation = absoluteLocation
        absoluteLocation = newLocation
    }

    // weak var window: UIWindow? // unused

    public func location(in view: UIView?) -> CGPoint {
        return UIWindow.main.convert(absoluteLocation, to: view)
    }

    public func previousLocation(in view: UIView?) -> CGPoint {
        return UIWindow.main.convert(previousAbsoluteLocation, to: view)
    }

}


extension UITouch: Hashable {
    public var hashValue: Int {
        return touchId
    }

    static public func == (lhs: UITouch, rhs: UITouch) -> Bool {
        return lhs.touchId == rhs.touchId
    }
}
