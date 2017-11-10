//
//  UITouch.swift
//  UIKit
//
//  Created by Geordie Jay on 29.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public class UITouch {
    static var activeTouches = Set<UITouch>()

    // XXX: remove UIView parameter from this initializer,
    // since it's an optional?
    init(at point: CGPoint, in view: UIView, touchId: Int) {
        self.view = view
        positionInView = point
        previousPositionInView = point
        self.touchId = touchId
    }

    var touchId: Int
    public var view: UIView?
    public var gestureRecognizers: [UIGestureRecognizer] = []

    /*
     * XXX: are these correctly named? should they not be named
     * "absolutePosition" and "previousAbsolutePosition"?
     * or to be even more consistent "absoluteLocation"
     * and "previousAbsoluteLocation?
     */
    var positionInView: CGPoint
    var previousPositionInView: CGPoint

    // var window: UIWindow? // unused

    public func location(in view: UIView?) -> CGPoint {
        return self.view?.convert(positionInView, to: view) ?? positionInView
    }

    public func previousLocation(in view: UIView?) -> CGPoint {
        return self.view?.convert(previousPositionInView, to: view) ?? previousPositionInView
    }

}


extension UITouch: Hashable {
    public var hashValue: Int {
        return touchId.hashValue
    }

    static public func == (lhs: UITouch, rhs: UITouch) -> Bool {
        return lhs.touchId == rhs.touchId
    }
}
