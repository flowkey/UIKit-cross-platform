//
//  TouchHandlingTests.swift
//  UIKitTests
//
//  Created by Michael Knoch on 21.02.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

@MainActor
class TouchHandlingTests: XCTestCase {
    private var window = UIWindow()
    private var event = UIEvent()
    private var view = ResponderView()
    private var recognizer = TestGestureRecognizer()
    private var subsubview = UIView()

    override func setUp() {
        UIEvent.activeEvents.removeAll() // isolate from touches a prior test may not have ended
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

    func testCancelsTouchesInViewWithTapGestureRecognizer() {
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.cancelsTouchesInView = true
        view.addGestureRecognizer(tapRecognizer)

        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchUp(CGPoint(x: 10, y: 10))

        XCTAssertFalse(view.touchesBeganWasCalled)
        XCTAssertFalse(view.touchesEndedWasCalled)
    }

    func testCancelsTouchesInViewWithPanGestureRecognizer() {
        recognizer.cancelsTouchesInView = true

        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchMove(CGPoint(x: 15, y: 10))
        handleTouchUp(CGPoint(x: 15, y: 10))

        XCTAssertTrue(view.touchesBeganWasCalled)

        XCTAssertFalse(view.touchesMovedWasCalled)
        XCTAssertFalse(view.touchesEndedWasCalled)
    }

    func testDoesNotCancelTouchesInView() {
        recognizer.cancelsTouchesInView = false

        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchMove(CGPoint(x: 15, y: 10))
        handleTouchUp(CGPoint(x: 15, y: 10))

        XCTAssertTrue(view.touchesMovedWasCalled)
        XCTAssertTrue(view.touchesEndedWasCalled)
    }

    func testShouldNotRecognizeSimultaneously() {
        let anotherRecognizer = TestGestureRecognizer()
        let anotherView = UIView()
        anotherView.frame = view.bounds
        anotherView.addGestureRecognizer(anotherRecognizer)
        view.addSubview(anotherView)

        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchMove(CGPoint(x: 15, y: 10))
        handleTouchUp(CGPoint(x: 15, y: 10))

        XCTAssertFalse(recognizer.onActionWasCalled)
        XCTAssertTrue(anotherRecognizer.onActionWasCalled)
    }

    func testSecondFingerJoinsTheSameEvent() {
        touchDown(id: 0, CGPoint(x: 100, y: 100))
        touchDown(id: 1, CGPoint(x: 200, y: 100))

        XCTAssertEqual(UIEvent.activeEvents.count, 1)
        XCTAssertEqual(UIEvent.activeEvents.first?.allTouches?.count, 2)
    }

    func testPinchBeginsOnSecondFingerAndReportsScale() {
        let pinch = UIPinchGestureRecognizer()
        view.addGestureRecognizer(pinch)

        touchDown(id: 0, CGPoint(x: 100, y: 100))
        touchDown(id: 1, CGPoint(x: 200, y: 100)) // fingers 100pt apart
        XCTAssertEqual(pinch.state, .began)

        touchMove(id: 1, CGPoint(x: 300, y: 100)) // now 200pt apart, so scale doubles
        XCTAssertEqual(pinch.state, .changed)
        XCTAssertEqual(pinch.scale, 2, accuracy: 0.0001)
    }

    func testSingleFingerDoesNotBeginPinch() {
        let pinch = UIPinchGestureRecognizer()
        view.addGestureRecognizer(pinch)

        touchDown(id: 0, CGPoint(x: 100, y: 100))
        touchMove(id: 0, CGPoint(x: 150, y: 100))

        XCTAssertEqual(pinch.state, .possible)
        XCTAssertEqual(pinch.scale, 1)
    }

}

private extension TouchHandlingTests {
    class ResponderView: UIView {
        var touchesBeganWasCalled = false
        var touchesMovedWasCalled = false
        var touchesEndedWasCalled = false

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            touchesBeganWasCalled = true
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            touchesMovedWasCalled = true
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            touchesEndedWasCalled = true
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
        let touch = UITouch(touchId: 0, at: point, timestamp: 0)
        touch.window = window
        let event = UIEvent(touch: touch)
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

    // Multi-finger variants: an extra finger joins the existing active event, matching the real SDL path.
    func touchDown(id: Int, _ point: CGPoint) {
        let touch = UITouch(touchId: id, at: point, timestamp: 0)
        touch.window = window
        if let event = UIEvent.activeEvents.first {
            event.allTouches?.insert(touch)
            event.changedTouch = touch
            window.sendEvent(event)
        } else {
            window.sendEvent(UIEvent(touch: touch))
        }
    }

    func touchMove(id: Int, _ point: CGPoint) {
        guard
            let event = UIEvent.activeEvents.first,
            let touch = event.allTouches?.first(where: { $0.touchId == id })
        else { return }
        touch.updateAbsoluteLocation(point)
        touch.phase = .moved
        event.changedTouch = touch
        window.sendEvent(event)
    }
}
