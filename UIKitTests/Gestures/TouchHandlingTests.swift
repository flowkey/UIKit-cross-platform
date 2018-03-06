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
    var viewOnTouchesMovedWasCalled = false
    var recognizerOnActionWasCalled = false

    var window = UIWindow()
    var subsubview = UIView()
    var event = UIEvent()

    override func setUp() {
        event = UIEvent()
        window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 1000, height: 1000)))
        let view = ResponderView(frame: window.bounds)
        window.addSubview(view)

        let viewRecognizer = UIPanGestureRecognizer(onAction: { self.recognizerOnActionWasCalled = true })
        view.addGestureRecognizer(viewRecognizer)
        let subview = UIView(frame: window.bounds)
        view.addSubview(subview)
        view.onTouchesMoved = { self.viewOnTouchesMovedWasCalled = true }

        subsubview = UIView(frame: window.bounds)
        subview.addSubview(subsubview)

        viewOnTouchesMovedWasCalled = false
        recognizerOnActionWasCalled = false
    }

    func testRecognizerOnActionWasCalled() {
        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchMove(CGPoint(x: 15, y: 10))
        handleTouchUp(CGPoint(x: 15, y: 10))

        XCTAssertTrue(recognizerOnActionWasCalled)
    }

    func testCancelsTouchesInView() {
        let anotherSubview = UIView(frame: window.bounds)
        subsubview.addSubview(anotherSubview)

        var anotherGestureRecognizerOnActionWasCalled = false
        let anotherGestureRecognizer = UIPanGestureRecognizer(onAction: { anotherGestureRecognizerOnActionWasCalled = true })
        anotherSubview.addGestureRecognizer(anotherGestureRecognizer)


        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchMove(CGPoint(x: 15, y: 10))
        handleTouchUp(CGPoint(x: 15, y: 10))

        XCTAssertFalse(viewOnTouchesMovedWasCalled)
        XCTAssertTrue(anotherGestureRecognizerOnActionWasCalled)
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

        XCTAssertTrue(viewOnTouchesMovedWasCalled)
    }

    private class ResponderView: UIView {
        public var onTouchesMoved: (()->Void)?
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            onTouchesMoved?()
        }
    }
}

private extension TouchHandlingTests {
    func handleTouchDown(_ point: CGPoint) {
        let event = UIEvent(from: UITouch(touchId: 0, at: point, in: window))
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
