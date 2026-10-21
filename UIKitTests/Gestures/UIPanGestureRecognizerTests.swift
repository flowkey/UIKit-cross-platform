//
//  UIGestureRecognizerTests.swift
//  UIKitTests
//
//  Created by flowing erik on 22.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

fileprivate class TestPanGestureRecognizer: UIPanGestureRecognizer {
    var actionStates: [UIGestureRecognizerState] = []

    fileprivate init() {
        super.init()
        self.onAction = { [unowned self] in self.actionStates.append(self.state) }
    }
}

@MainActor
class UIPanGestureRecognizerTests: XCTestCase {
    var mockView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))

    var window: UIWindow = UIWindow()

    override func setUp() {
        mockView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
    }

    func testPanGestureRecognizerStateEnded() {
        let recognizer = TestPanGestureRecognizer()
        let touch = begin(recognizer, at: CGPoint(x: 42, y: 12))
        XCTAssertEqual(recognizer.state, .possible)

        move(touch, to: CGPoint(x: 34, y: 45), on: recognizer)
        XCTAssertEqual(recognizer.state, .began)

        move(touch, to: CGPoint(x: 30, y: 50), on: recognizer)
        XCTAssertEqual(recognizer.state, .changed)

        touch.phase = .ended
        recognizer.touchesEnded([touch], with: UIEvent())

        XCTAssertEqual(recognizer.actionStates, [.began, .changed, .ended])
        XCTAssertEqual(recognizer.state, .possible)
    }

    func testPanGestureRecognizerStateCancelled() {
        let recognizer = TestPanGestureRecognizer()
        let touch = begin(recognizer, at: CGPoint(x: 12, y: 42))
        move(touch, to: CGPoint(x: 23, y: 21), on: recognizer)
        XCTAssertEqual(recognizer.state, .began)

        recognizer.touchesCancelled([touch], with: UIEvent())

        XCTAssertEqual(recognizer.actionStates, [.began, .cancelled])
        XCTAssertEqual(recognizer.state, .possible)
    }

    func testPanDoesNotBeginBeforeTheTouchMovedTenPoints() {
        let recognizer = TestPanGestureRecognizer()
        let touch = begin(recognizer, at: .zero)

        move(touch, to: CGPoint(x: 6, y: 6), on: recognizer)
        XCTAssertEqual(recognizer.state, .possible)

        move(touch, to: CGPoint(x: 8, y: 8), on: recognizer)
        XCTAssertEqual(recognizer.state, .began)
    }

    func testActionIsSentOnEveryChange() {
        let recognizer = TestPanGestureRecognizer()
        let touch = begin(recognizer, at: .zero)

        for x in stride(from: 20, through: 60, by: 10) {
            move(touch, to: CGPoint(x: CGFloat(x), y: 0), on: recognizer)
        }

        XCTAssertEqual(recognizer.actionStates, [.began, .changed, .changed, .changed, .changed])
    }

    func testVelocity() {
        let recognizer = UIPanGestureRecognizer()
        let touch = begin(recognizer, at: .zero)

        touch.timestamp = 0.05
        move(touch, to: CGPoint(x: 50, y: 0), on: recognizer)

        XCTAssertEqual(recognizer.velocity(in: mockView).x, 1000, accuracy: 0.001)
    }

    func testTouchesMovedUpdatesTranslation() {
        let recognizer = UIPanGestureRecognizer()
        let touch = UITouch(touchId: 0, at: .zero, timestamp: 0)
        touch.window = window
        let location = CGPoint(x: 10, y: 10)

        recognizer.view = mockView

        // begin touch, check initial translation
        recognizer.add(touch)
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
        let touch = UITouch(touchId: 0, at: .zero, timestamp: 0)
        touch.window = window

        recognizer.view = mockView
        recognizer.add(touch)
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

        let touch = UITouch(touchId: 0, at: CGPoint(x: 10, y: 10), timestamp: 0)
        touch.window = window
        touch.view = view
        panGestureRecognizer.add(touch)
        panGestureRecognizer.touchesBegan([touch], with: UIEvent())

        touch.updateAbsoluteLocation(CGPoint(x: 20, y: 20))
        panGestureRecognizer.touchesMoved([touch], with: UIEvent())

        panGestureRecognizer.setTranslation(.zero, in: view)

        touch.updateAbsoluteLocation(CGPoint(x: 30, y: 30))
        panGestureRecognizer.touchesMoved([touch], with: UIEvent())

        XCTAssertEqual(panGestureRecognizer.translation(in: view), CGPoint(x: 10, y: 10))
    }

    @discardableResult
    private func begin(_ recognizer: UIPanGestureRecognizer, at point: CGPoint) -> UITouch {
        let touch = UITouch(touchId: 0, at: point, timestamp: 0)
        touch.window = window
        touch.view = mockView
        recognizer.add(touch)
        recognizer.touchesBegan([touch], with: UIEvent())
        return touch
    }

    private func move(_ touch: UITouch, to point: CGPoint, on recognizer: UIPanGestureRecognizer) {
        touch.phase = .moved
        touch.updateAbsoluteLocation(point)
        recognizer.touchesMoved([touch], with: UIEvent())
    }
}
