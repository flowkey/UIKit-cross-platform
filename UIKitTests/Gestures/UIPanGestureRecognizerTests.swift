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
    let stateCancelledExpectation: XCTestExpectation?
    let stateEndedExpectation: XCTestExpectation?

    fileprivate init (cancelledExp: XCTestExpectation? = nil, endedExp: XCTestExpectation? = nil) {
        stateCancelledExpectation = cancelledExp
        stateEndedExpectation = endedExp
        super.init()
        self.onStateChanged = {
            switch self.state {
            case .ended: self.stateEndedExpectation?.fulfill()
            case .cancelled: self.stateCancelledExpectation?.fulfill()
            default: break
            }
        }
    }
}

class UIPanGestureRecognizerTests: XCTestCase {
    var mockTouch: UITouch!
    let mockView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
    override func setUp() {
        mockTouch = UITouch(
            at: CGPoint(x: 0, y: 0),
            in: mockView,
            touchId: 0
        )
    }

    func testPanGestureRecognizerStateEnded() {
        let endedExpectation = expectation(description: "State was ended")
        let pgr = TestPanGestureRecognizer(endedExp: endedExpectation)

        pgr.touchesBegan([mockTouch], with: UIEvent())
        XCTAssert(pgr.state == .began)

        mockTouch.positionInView = CGPoint(x: 100, y: 100)
        pgr.touchesMoved([mockTouch], with: UIEvent())
        XCTAssert(pgr.state == .changed)

        pgr.touchesEnded([mockTouch], with: UIEvent())

        // expect that state was .ended at some point
        wait(for: [endedExpectation], timeout: 2)

        // state should transition to .possible after being .ended
        XCTAssert(pgr.state == .possible)
    }

    func testPanGestureRecognizerStateCancelled() {
        let cancelledExpectation = expectation(description: "State was cancelled")
        let pgr = TestPanGestureRecognizer(cancelledExp: cancelledExpectation)

        pgr.touchesBegan([mockTouch], with: UIEvent())
        XCTAssert(pgr.state == .began)

        mockTouch.positionInView = CGPoint(x: 100, y: 100)
        pgr.touchesMoved([mockTouch], with: UIEvent())
        XCTAssert(pgr.state == .changed)

        pgr.touchesCancelled([mockTouch], with: UIEvent())

        // expect that state was .cancelled at some point
        wait(for: [cancelledExpectation], timeout: 1)

        // state should transition to .possible after being .cancelled
        XCTAssert(pgr.state == .possible)
    }

    func testVelocity() {
        let touchPositionDiff: CGFloat = 50
        let timeInterval = 1.0

        let pgr = UIPanGestureRecognizer()
        let velocityExp = expectation(description: "velocity is as expected")

        self.mockTouch.previousPositionInView = CGPoint(x: 0, y: 0)
        self.mockTouch.positionInView = CGPoint(x: touchPositionDiff, y: 0)
        pgr.touchesBegan([mockTouch], with: UIEvent())
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeInterval) {
            pgr.touchesMoved([self.mockTouch], with: UIEvent())
            let velocityX = pgr.velocity(in: self.mockView).x
            let expectedVelocityX: CGFloat = touchPositionDiff / CGFloat(timeInterval)

            // we can not predict the exact velocity since we use DispatchTime.now
            // because of this we allow some deviation of a few percent
            if velocityX.isEqual(to: expectedVelocityX, percentalAccuracy: 5.0) {
                velocityExp.fulfill()
            }
        }

        wait(for: [velocityExp], timeout: 1.1)
    }

    func testSetTranslation() {
        let pgr = UIPanGestureRecognizer()
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        let touchPosition0 = CGPoint.zero
        let touchPosition1 = CGPoint(x: 10, y: 10)

        // begin touch, check initial translation
        let touch0 = UITouch(at: touchPosition0, in: view, touchId: 0)
        pgr.touchesBegan([touch0], with: UIEvent())
        XCTAssertEqual(pgr.translation(in: view), touchPosition0)

        // move touch, translation should be equal to touch position
        pgr.touchesMoved( [UITouch(at: touchPosition1, in: view, touchId: 0)], with: UIEvent())
        XCTAssertEqual(pgr.translation(in: view), touchPosition1)

        // set translation to a new arbitrary value
        let newTranslation = CGPoint(x: 12, y: 13)
        pgr.setTranslation(newTranslation, in: mockView)
        XCTAssertEqual(pgr.translation(in: mockView), newTranslation)
    }
}

fileprivate extension CGFloat {
    func isEqual(to value: CGFloat, percentalAccuracy: Double) -> Bool {
        let min = Double(value) - ((Double(value) * percentalAccuracy) / 100)
        let max = Double(value) + ((Double(value) * percentalAccuracy) / 100)
        return (min ..< max)~=(Double(self)) // if in range
    }
}
