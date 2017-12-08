//
//  UITouch.swift
//  UIKit
//
//  Created by Geordie Jay on 29.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public class UITouch {
    static var activeTouches = Set<UITouch>()

    // using this to convert SDL touches into UIView touches
    internal init(at point: CGPoint, in view: UIView, touchId: Int) {
        self.view = view
        locationInView = point
        previousLocationInView = point
        self.touchId = touchId
    }

    var touchId: Int
    public var view: UIView?
    public var gestureRecognizers: [UIGestureRecognizer] = []

    private var locationInView: CGPoint
    private var previousLocationInView: CGPoint

    func updateLocationInView(_ newLocation: CGPoint) {
        previousLocationInView = locationInView
        locationInView = newLocation
    }

    // var window: UIWindow? // unused

    public func location(in view: UIView?) -> CGPoint {
        return self.view?.convert(locationInView, to: view) ?? locationInView
    }

    public func previousLocation(in view: UIView?) -> CGPoint {
        return self.view?.convert(previousLocationInView, to: view) ?? previousLocationInView
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
