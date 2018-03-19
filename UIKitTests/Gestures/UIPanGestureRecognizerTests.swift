//
//  UIGestureRecognizerTests.swift
//  UIKitTests
//
//  Created by flowing erik on 22.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit
import Foundation



fileprivate class TestPanGestureRecognizer: UIPanGestureRecognizer {
    let stateCancelledExpectation: XCTestExpectation?
    let stateEndedExpectation: XCTestExpectation?

    fileprivate init (cancelledExp: XCTestExpectation? = nil, endedExp: XCTestExpectation? = nil) {
        stateCancelledExpectation = cancelledExp
        stateEndedExpectation = endedExp
        super.init()
        self.onStateChanged = { [weak self] in
            guard let state = self?.state else { return }
            switch state {
            case .ended: self?.stateEndedExpectation?.fulfill()
            case .cancelled: self?.stateCancelledExpectation?.fulfill()
            default: break
            }
        }
    }
}

class UIPanGestureRecognizerTests: XCTestCase {
    var mockView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))

    var window: UIWindow = UIWindow()

    override func setUp() {
        mockView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
    }

    func testPanGestureRecognizerStateEnded() {
        let endedExpectation = expectation(description: "State was ended")
        let recognizer = TestPanGestureRecognizer(endedExp: endedExpectation)

        let location0 = CGPoint(x: 42, y: 12)
        let touch = UITouch(touchId: 0, at: location0, in: window, timestamp: 0)
        touch.view = mockView
        recognizer.touchesBegan([touch], with: UIEvent())
        XCTAssert(recognizer.state == .began)

        let location1 = CGPoint(x: 34, y: 45)
        touch.updateAbsoluteLocation(location1)
        recognizer.touchesMoved([touch], with: UIEvent())
        XCTAssert(recognizer.state == .changed)

        recognizer.touchesEnded([touch], with: UIEvent())

        // expect that state was .ended at some point
        wait(for: [endedExpectation], timeout: 2)

        // state should transition to .possible after being .ended
        XCTAssert(recognizer.state == .possible)
    }

    func testPanGestureRecognizerStateCancelled() {
        let cancelledExpectation = expectation(description: "State was cancelled")
        let recognizer = TestPanGestureRecognizer(cancelledExp: cancelledExpectation)

        let location0 = CGPoint(x: 12, y: 42)
        let touch = UITouch(touchId: 0, at: location0, in: window, timestamp: 0)

        recognizer.touchesBegan([touch], with: UIEvent())
        XCTAssert(recognizer.state == .began)

        let location1 = CGPoint(x: 23, y: 21)
        touch.updateAbsoluteLocation(location1)
        recognizer.touchesMoved([touch], with: UIEvent())
        XCTAssert(recognizer.state == .changed)


        recognizer.touchesCancelled([touch], with: UIEvent())

        // expect that state was .cancelled at some point
        wait(for: [cancelledExpectation], timeout: 1)

        // state should transition to .possible after being .cancelled
        XCTAssert(recognizer.state == .possible)
    }

    func testVelocity() {
        let touchPositionDiff: CGFloat = 50
        let timeInterval = 1.0

        let recognizer = UIPanGestureRecognizer()
        let touch = UITouch(touchId: 0, at: .zero, in: window, timestamp: 0)
        recognizer.touchesBegan([touch], with: UIEvent())

        touch.updateAbsoluteLocation(CGPoint(x: touchPositionDiff, y: 0))
        recognizer.touchesMoved([touch], with: UIEvent())

        let velocityX = recognizer.velocity(in: self.mockView, timeDiffSeconds: timeInterval).x
        let expectedVelocityX: CGFloat = touchPositionDiff / CGFloat(timeInterval)
        XCTAssertEqual(velocityX, expectedVelocityX, accuracy: 0.001)
    }

    func testTouchesMovedUpdatesTranslation() {
        let recognizer = UIPanGestureRecognizer()
        let touch = UITouch(touchId: 0, at: .zero, in: window, timestamp: 0)
        let location = CGPoint(x: 10, y: 10)

        recognizer.view = mockView

        // begin touch, check initial translation
        recognizer.touchesBegan([touch], with: UIEvent())
        XCTAssertEqual(recognizer.translation(in: mockView), .zero)

        // move touch, translation should be equal to touch position
        touch.updateAbsoluteLocation(location)
        recognizer.touchesMoved([touch], with: UIEvent())
        XCTAssertEqual(recognizer.translation(in: mockView), location)
    }

    func testSetTranslation() {
        let recognizer = UIPanGestureRecognizer()
        let newTranslation = CGPoint(x: 12, y: 13)
        let touch = UITouch(touchId: 0, at: .zero, in: window, timestamp: 0)

        recognizer.view = mockView
        recognizer.touchesBegan([touch], with: UIEvent())
        recognizer.setTranslation(newTranslation, in: mockView)

        XCTAssertEqual(recognizer.translation(in: mockView), newTranslation)
    }

    func testTranslateAndReset() {
        let rootView = UIView()
        let view = UIView(frame: CGRect(x: 50, y: 50, width: 100, height: 100))
        let panGestureRecognizer = UIPanGestureRecognizer()

        view.addGestureRecognizer(panGestureRecognizer)
        rootView.addSubview(view)

        let touch = UITouch(touchId: 0, at: CGPoint(x: 10, y: 10), in: window, timestamp: 0)
        touch.view = view
        panGestureRecognizer.touchesBegan([touch], with: UIEvent())

        touch.updateAbsoluteLocation(CGPoint(x: 20, y: 20))
        panGestureRecognizer.touchesMoved([touch], with: UIEvent())

        panGestureRecognizer.setTranslation(.zero, in: view)

        touch.updateAbsoluteLocation(CGPoint(x: 30, y: 30))
        panGestureRecognizer.touchesMoved([touch], with: UIEvent())

        XCTAssertEqual(panGestureRecognizer.translation(in: view), CGPoint(x: 10, y: 10))
    }
}
