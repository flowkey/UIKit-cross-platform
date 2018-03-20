//
//  TouchHandlingTests.swift
//  UIKitTests
//
//  Created by Michael Knoch on 21.02.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

class TouchHandlingTests: XCTestCase {
    private var window = UIWindow()
    private var event = UIEvent()
    private var view = ResponderView()
    private var recognizer = TestGestureRecognizer()
    private var subsubview = UIView()

    override func setUp() {
        event = UIEvent()
        window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 1000, height: 1000)))

        view = ResponderView(frame: window.bounds)
        window.addSubview(view)

        recognizer = TestGestureRecognizer()
        view.addGestureRecognizer(recognizer)
        let subview = UIView(frame: window.bounds)
        view.addSubview(subview)

        subsubview = UIView(frame: window.bounds)
        subview.addSubview(subsubview)
    }

    func testRecognizerOnActionWasCalled() {
        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchMove(CGPoint(x: 15, y: 10))
        handleTouchUp(CGPoint(x: 15, y: 10))

        XCTAssertTrue(recognizer.onActionWasCalled)
    }

    func testCancelsTouchesInView() {
        let anotherSubview = UIView(frame: window.bounds)
        subsubview.addSubview(anotherSubview)

        let anotherGestureRecognizer = TestGestureRecognizer()
        anotherSubview.addGestureRecognizer(anotherGestureRecognizer)

        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchMove(CGPoint(x: 15, y: 10))
        handleTouchUp(CGPoint(x: 15, y: 10))

        XCTAssertFalse(view.touchesMovedWasCalled)
        XCTAssertTrue(anotherGestureRecognizer.onActionWasCalled)
    }

    func testDoesNotCancelTouchesInView() {
        let anotherSubview = UIView(frame: window.bounds)
        subsubview.addSubview(anotherSubview)

        let anotherGestureRecognizer = UIGestureRecognizer()
        anotherGestureRecognizer.cancelsTouchesInView = false
        anotherSubview.addGestureRecognizer(anotherGestureRecognizer)

        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchMove(CGPoint(x: 15, y: 10))
        handleTouchUp(CGPoint(x: 15, y: 10))

        XCTAssertTrue(view.touchesMovedWasCalled)
    }
}

private extension TouchHandlingTests {
    class ResponderView: UIView {
        var touchesMovedWasCalled = false
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            touchesMovedWasCalled = true
        }
    }

    class TestGestureRecognizer: UIPanGestureRecognizer {
        var onActionWasCalled = false
        init() {
            super.init()
            self.onAction = { self.onActionWasCalled = true }
        }
    }
}

private extension TouchHandlingTests {
    func handleTouchDown(_ point: CGPoint) {
        let event = UIEvent(touch: UITouch(touchId: 0, at: point, in: window, timestamp: 0))
        window.sendEvent(event)
    }

    func handleTouchMove(_ point: CGPoint) {
        if
            let event = UIEvent.activeEvents.first,
            let touch = event.allTouches?.first(where: { $0.touchId == Int(0) } )
        {
            touch.updateAbsoluteLocation(point)
            touch.phase = .moved
            window.sendEvent(event)
        }
    }

    func handleTouchUp(_ point: CGPoint) {
        if
            let event = UIEvent.activeEvents.first,
            let touch = event.allTouches?.first(where: { $0.touchId == Int(0) } )
        {
            touch.phase = .ended
            window.sendEvent(event)
        }
    }
}
