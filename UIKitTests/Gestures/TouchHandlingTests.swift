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

    override func tearDown() {
        UIEvent.activeEvents.removeAll()
        UIGestureRecognizer.resetFinishedRecognizers()
    }

    func testRecognizerOnActionWasCalled() {
        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchMove(CGPoint(x: 35, y: 10))
        handleTouchUp(CGPoint(x: 35, y: 10))

        XCTAssertTrue(recognizer.onActionWasCalled)
    }

    func testCancelsTouchesInViewWithTapGestureRecognizer() {
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.cancelsTouchesInView = true
        view.addGestureRecognizer(tapRecognizer)

        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchUp(CGPoint(x: 10, y: 10))

        XCTAssertTrue(view.touchesBeganWasCalled)
        XCTAssertFalse(view.touchesEndedWasCalled)
        XCTAssertTrue(view.touchesCancelledWasCalled)
    }

    func testCancelsTouchesInViewWithPanGestureRecognizer() {
        recognizer.cancelsTouchesInView = true

        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchMove(CGPoint(x: 35, y: 10))
        handleTouchUp(CGPoint(x: 35, y: 10))

        XCTAssertTrue(view.touchesBeganWasCalled)

        XCTAssertFalse(view.touchesMovedWasCalled)
        XCTAssertFalse(view.touchesEndedWasCalled)
        XCTAssertTrue(view.touchesCancelledWasCalled)
    }

    func testDoesNotCancelTouchesInView() {
        recognizer.cancelsTouchesInView = false

        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchMove(CGPoint(x: 35, y: 10))
        handleTouchUp(CGPoint(x: 35, y: 10))

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
        handleTouchMove(CGPoint(x: 35, y: 10))
        handleTouchUp(CGPoint(x: 35, y: 10))

        XCTAssertFalse(recognizer.onActionWasCalled)
        XCTAssertTrue(anotherRecognizer.onActionWasCalled)
    }

    func testTapFailsWhenTheTouchMoves() {
        view.removeGestureRecognizer(recognizer)
        var tapped = false
        view.addGestureRecognizer(UITapGestureRecognizer(onAction: { tapped = true }))

        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchMove(CGPoint(x: 25, y: 10))
        handleTouchUp(CGPoint(x: 25, y: 10))

        XCTAssertFalse(tapped)
    }

    func testFailedRecognizerStaysFailedUntilTheTouchesEnd() {
        let tap = UITapGestureRecognizer()
        view.addGestureRecognizer(tap)

        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchMove(CGPoint(x: 35, y: 10))
        XCTAssertEqual(tap.state, .failed)

        handleTouchUp(CGPoint(x: 35, y: 10))
        XCTAssertEqual(tap.state, .possible)
    }

    func testRequireToFailWaitsForTheOtherRecognizer() {
        var tapped = false
        let twoFingerTap = UITapGestureRecognizer()
        twoFingerTap.numberOfTouchesRequired = 2
        let tap = UITapGestureRecognizer(onAction: {
            tapped = true
            XCTAssertEqual(twoFingerTap.state, .failed)
        })
        tap.require(toFail: twoFingerTap)
        view.addGestureRecognizer(twoFingerTap)
        subsubview.addGestureRecognizer(tap)

        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchUp(CGPoint(x: 10, y: 10))

        XCTAssertTrue(tapped)
    }

    func testLongPressBeginsAfterTheMinimumPressDuration() {
        let began = expectation(description: "Long press began")
        let longPress = UILongPressGestureRecognizer()
        longPress.minimumPressDuration = 0.05
        longPress.onAction = { [unowned longPress] in if longPress.state == .began { began.fulfill() } }
        view.addGestureRecognizer(longPress)

        handleTouchDown(CGPoint(x: 10, y: 10))
        XCTAssertEqual(longPress.state, .possible)

        wait(for: [began], timeout: 1)
        handleTouchUp(CGPoint(x: 10, y: 10))
        XCTAssertEqual(longPress.state, .possible)
    }

    func testLongPressFailsWhenTheFingerMoves() {
        view.removeGestureRecognizer(recognizer)
        let longPress = UILongPressGestureRecognizer()
        view.addGestureRecognizer(longPress)

        handleTouchDown(CGPoint(x: 10, y: 10))
        handleTouchMove(CGPoint(x: 25, y: 10))

        XCTAssertEqual(longPress.state, .failed)
    }

    func testLongPressEndsWhenAnyFingerLifts() {
        let began = expectation(description: "Long press began")
        let longPress = UILongPressGestureRecognizer()
        longPress.minimumPressDuration = 0.05
        longPress.numberOfTouchesRequired = 2
        longPress.onAction = { [unowned longPress] in if longPress.state == .began { began.fulfill() } }
        view.addGestureRecognizer(longPress)

        touchDown(id: 0, CGPoint(x: 100, y: 100))
        touchDown(id: 1, CGPoint(x: 200, y: 100))
        wait(for: [began], timeout: 1)
        touchUp(id: 1)

        XCTAssertEqual(longPress.state, .ended)
    }

    func testPanTranslationDoesNotJumpWhenAFingerJoins() {
        view.removeGestureRecognizer(recognizer)
        let pan = UIPanGestureRecognizer()
        view.addGestureRecognizer(pan)

        touchDown(id: 0, CGPoint(x: 100, y: 100))
        touchMove(id: 0, CGPoint(x: 130, y: 100))
        touchDown(id: 1, CGPoint(x: 300, y: 100))

        XCTAssertEqual(pan.translation(in: nil), CGPoint(x: 30, y: 0))
    }

    func testFailedRecognizerDoesNotEndWhenItsTouchLifts() {
        view.removeGestureRecognizer(recognizer)
        var longPressActions = 0
        let longPress = UILongPressGestureRecognizer(onAction: { longPressActions += 1 })
        longPress.numberOfTouchesRequired = 2
        view.addGestureRecognizer(longPress)

        touchDown(id: 0, CGPoint(x: 100, y: 100))
        touchDown(id: 1, CGPoint(x: 200, y: 100))
        touchMove(id: 0, CGPoint(x: 150, y: 100))
        touchUp(id: 0)

        XCTAssertEqual(longPressActions, 0)
        XCTAssertEqual(longPress.state, .failed)
    }

    func testScrollViewTellsItsDelegateWhenAFlingStopsDecelerating() {
        let delegate = ScrollViewDelegateSpy()
        let scrollView = flingScrollView(delegate: delegate)

        XCTAssertTrue(scrollView.isDecelerating)
        UIView.completePendingAnimations()
        XCTAssertFalse(scrollView.isDecelerating)
        XCTAssertTrue(delegate.didEndDecelerating)
    }

    func testTouchDownStopsAScrollViewDeceleration() {
        let delegate = ScrollViewDelegateSpy()
        let scrollView = flingScrollView(delegate: delegate)

        handleTouchDown(CGPoint(x: 500, y: 100))

        XCTAssertFalse(scrollView.isDecelerating)
        XCTAssertFalse(delegate.didEndDecelerating)
    }

    private func flingScrollView(delegate: UIScrollViewDelegate) -> UIScrollView {
        let scrollView = UIScrollView(frame: window.bounds)
        scrollView.contentSize = CGSize(width: 5000, height: window.bounds.height)
        scrollView.contentOffset = CGPoint(x: 2000, y: 0)
        scrollView.delegate = delegate
        window.addSubview(scrollView)

        let touch = UITouch(touchId: 0, at: CGPoint(x: 600, y: 100), timestamp: 0)
        touch.window = window
        let event = UIEvent(touch: touch)
        window.sendEvent(event)
        for (x, timestamp) in [(500.0, 0.02), (400.0, 0.04)] {
            touch.timestamp = timestamp
            touch.updateAbsoluteLocation(CGPoint(x: x, y: 100))
            touch.phase = .moved
            window.sendEvent(event)
        }
        touch.phase = .ended
        window.sendEvent(event)
        return scrollView
    }

    func testSecondFingerJoinsTheSameEvent() {
        touchDown(id: 0, CGPoint(x: 100, y: 100))
        touchDown(id: 1, CGPoint(x: 200, y: 100))

        XCTAssertEqual(UIEvent.activeEvents.count, 1)
        XCTAssertEqual(UIEvent.activeEvents.first?.allTouches?.count, 2)
    }

    func testPinchBeginsWhenTheFingersMoveAndReportsScale() {
        view.removeGestureRecognizer(recognizer) // a pan on the same view would begin first
        let pinch = UIPinchGestureRecognizer()
        view.addGestureRecognizer(pinch)

        touchDown(id: 0, CGPoint(x: 100, y: 100))
        touchDown(id: 1, CGPoint(x: 200, y: 100)) // fingers 100pt apart
        XCTAssertEqual(pinch.state, .possible)

        touchMove(id: 1, CGPoint(x: 300, y: 100)) // now 200pt apart, so scale doubles
        XCTAssertEqual(pinch.state, .began)
        XCTAssertEqual(pinch.scale, 2, accuracy: 0.0001)

        touchMove(id: 1, CGPoint(x: 400, y: 100))
        XCTAssertEqual(pinch.state, .changed)
        XCTAssertEqual(pinch.scale, 3, accuracy: 0.0001)
    }

    func testSingleFingerDoesNotBeginPinch() {
        view.removeGestureRecognizer(recognizer)
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
        var touchesCancelledWasCalled = false

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            touchesBeganWasCalled = true
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            touchesMovedWasCalled = true
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            touchesEndedWasCalled = true
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            touchesCancelledWasCalled = true
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

    func touchUp(id: Int) {
        guard
            let event = UIEvent.activeEvents.first,
            let touch = event.allTouches?.first(where: { $0.touchId == id })
        else { return }
        touch.phase = .ended
        event.changedTouch = touch
        window.sendEvent(event)
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

@MainActor
private final class ScrollViewDelegateSpy: UIScrollViewDelegate {
    var didEndDecelerating = false
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { didEndDecelerating = true }
}
