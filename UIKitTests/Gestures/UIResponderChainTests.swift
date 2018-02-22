//
//  UIResponderChainTests.swift
//  UIKitTests
//
//  Created by Michael Knoch on 21.02.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

class UIResponderChainTests: XCTestCase {
    var window = UIWindow()
    var viewOnTouchesBeganWasCalled = false
    var viewRecognizerOnActionWasCalled = false
    var subsubview: UIView = UIView()
    var event = UIEvent()

    override func setUp() {
        event = UIEvent()
        window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 1000, height: 1000)))
        let view = ResponderView(frame: window.bounds)
        view.onTouchesBegan = { self.viewOnTouchesBeganWasCalled = true }
        window.addSubview(view)

        let viewRecognizer = UIPanGestureRecognizer()
        view.addGestureRecognizer(viewRecognizer)
        
        viewRecognizerOnActionWasCalled = false
        viewRecognizer.onAction = { self.viewRecognizerOnActionWasCalled = true }

        let subview = UIView(frame: window.bounds)
        view.addSubview(subview)

        subsubview = UIView(frame: window.bounds)
        subview.addSubview(subsubview)
    }

    func testResponderChainTriggersGestureRecognizers() {
        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchMove(CGPoint(x: 15, y: 10))
        handleTouchUp(CGPoint(x: 15, y: 10))

        XCTAssertTrue(viewRecognizerOnActionWasCalled)
    }

    func testCancelsTouchesInViewTrue() {
        let anotherSubview = UIView(frame: window.bounds)
        subsubview.addSubview(anotherSubview)

        let anotherGestureRecognizer = UIPanGestureRecognizer()
        anotherSubview.addGestureRecognizer(anotherGestureRecognizer)

        var anotherGestureRecognizerOnActionWasCalled = false
        anotherGestureRecognizer.onAction = { anotherGestureRecognizerOnActionWasCalled = true }

        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchMove(CGPoint(x: 15, y: 10))
        handleTouchUp(CGPoint(x: 15, y: 10))

        XCTAssertFalse(viewOnTouchesBeganWasCalled)
        XCTAssertTrue(anotherGestureRecognizerOnActionWasCalled)
    }

    func testCancelsTouchesInViewFalse() {
        let anotherSubview = UIView(frame: window.bounds)
        subsubview.addSubview(anotherSubview)

        let anotherGestureRecognizer = UIGestureRecognizer()
        anotherGestureRecognizer.cancelsTouchesInView = false
        anotherSubview.addGestureRecognizer(anotherGestureRecognizer)

        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchMove(CGPoint(x: 15, y: 10))
        handleTouchUp(CGPoint(x: 15, y: 10))

        XCTAssertTrue(viewOnTouchesBeganWasCalled)
    }

    class ResponderView: UIView {
        public var onTouchesBegan: (()->Void)?
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            onTouchesBegan?()
        }
    }
}

fileprivate extension UIResponderChainTests {
    func handleTouchDown(_ point: CGPoint) {
        let event = UIEvent(from: UITouch(at: point, touchId: 0))
        window.sendEvent(event)
    }

    func handleTouchMove(_ point: CGPoint) {
        if
            let event = UIEvent.activeEvents.first,
            let touch = event.allTouches?.first(where: { $0.touchId == Int(0) } )
        {
            touch.updateAbsoluteLocation(point)
            event.phase = .moved
            window.sendEvent(event)
        }
    }

    func handleTouchUp(_ point: CGPoint) {
        if
            let event = UIEvent.activeEvents.first,
            let _ = event.allTouches?.first(where: { $0.touchId == Int(0) } )
        {
            event.phase = .ended
            window.sendEvent(event)
        }
    }
}
