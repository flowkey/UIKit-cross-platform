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
        let touch = UITouch(touchId: 0, at: location0, in: window)
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
        let touch = UITouch(touchId: 0, at: location0, in: window)

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

    func testVelocityTracker() {
        // test data
        let timestampsAndTranslations = Array(zip( // Array so we can .count
            [TimeInterval(100), TimeInterval(100), TimeInterval(100)],
            [CGPoint(x: 100, y: 100), CGPoint(x:100, y:100), CGPoint(x: 100, y: 100)]
        ))

        // create velocity tracker and track test data
        let velocityTracker = VelocityTracker(bufferSize: timestampsAndTranslations.count)
        timestampsAndTranslations.forEach {
            velocityTracker.track(timeInterval: $0, translation: $1)
        }

        // calculate expected velocity from test data
        let expectedMeanVelocity = calculateVelocityMean(from: timestampsAndTranslations)

        XCTAssertEqual(expectedMeanVelocity, velocityTracker.mean)
    }

    func testTouchesMovedUpdatesTranslation() {
        let recognizer = UIPanGestureRecognizer()
        let touch = UITouch(touchId: 0, at: .zero, in: window)
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
        let touch = UITouch(touchId: 0, at: .zero, in: window)

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

        let touch = UITouch(touchId: 0, at: CGPoint(x: 10, y: 10), in: window)
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

fileprivate func calculateVelocityMean(from timestampsAndTranslations: [(TimeInterval, CGPoint)]) -> CGPoint {
    let summedVelocity = timestampsAndTranslations.reduce(CGPoint.zero, { prev, tuple in
        let (timeInterval, translation) = tuple
        guard timeInterval != 0 else {
            return .zero
        }
        let singleVelocity = CGPoint(
            x: translation.x / CGFloat(timeInterval),
            y: translation.y / CGFloat(timeInterval)
        )
        return CGPoint(x: prev.x + singleVelocity.x, y: prev.y + singleVelocity.y)
    })
    return CGPoint(
        x: summedVelocity.x / CGFloat(timestampsAndTranslations.count),
        y: summedVelocity.y / CGFloat(timestampsAndTranslations.count)
    )
}
