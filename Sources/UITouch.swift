//
//  UITouch.swift
//  UIKit
//
//  Created by Geordie Jay on 29.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public class UITouch {

    internal init(touchId: Int, at point: CGPoint, in window: UIWindow) {
        absoluteLocation = point
        previousAbsoluteLocation = point
        self.touchId = touchId
        self.window = window
    }

    let touchId: Int

    public weak var view: UIView?
    public weak var window: UIWindow?

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

    public var gestureRecognizers: [UIGestureRecognizer] = []
    func runTouchActionOnRecognizerHierachy(_ action: (_ recognizer: UIGestureRecognizer) -> Void) {
        for recognizer in gestureRecognizers {
            action(recognizer)

            // actually continue when other recognizers shouldRecognizeSimultaneously
            return
        }
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

public enum UITouchPhase: Int {
    case began, moved, ended
}

