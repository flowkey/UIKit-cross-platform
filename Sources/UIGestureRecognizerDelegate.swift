//
//  UIGestureRecognizerDelegate.swift
//  UIKit
//
//  Created by Chris on 28.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

//The full implementation of UIGestureRecognizerDelegate should include also all the other methods as optional implementations. This is currently only possible with an @obj flag, which we want to avoid:
//@objc protocol SomeProtocol {
//    @objc optional func someFunc()
//}

public protocol UIGestureRecognizerDelegate {
//    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool

//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive: UITouch) -> Bool
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive: UIPress) -> Bool

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool

//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool
}
