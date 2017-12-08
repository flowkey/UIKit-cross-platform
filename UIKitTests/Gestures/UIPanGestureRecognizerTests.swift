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
    let mockView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))

    func testPanGestureRecognizerStateEnded() {
        let endedExpectation = expectation(description: "State was ended")
        let pgr = TestPanGestureRecognizer(endedExp: endedExpectation)

        let pos0 = CGPoint(x: 42, y: 12)
        let touch = UITouch(at: pos0, in: mockView, touchId: 0)

        pgr.touchesBegan([touch], with: UIEvent())
        XCTAssert(pgr.state == .began)

        let pos1 = CGPoint(x: 34, y: 45)
        touch.updatePositionInView(pos1)
        pgr.touchesMoved([touch], with: UIEvent())
        XCTAssert(pgr.state == .changed)

        pgr.touchesEnded([touch], with: UIEvent())

        // expect that state was .ended at some point
        wait(for: [endedExpectation], timeout: 2)

        // state should transition to .possible after being .ended
        XCTAssert(pgr.state == .possible)
    }

    func testPanGestureRecognizerStateCancelled() {
        let cancelledExpectation = expectation(description: "State was cancelled")
        let pgr = TestPanGestureRecognizer(cancelledExp: cancelledExpectation)

        let pos0 = CGPoint(x: 12, y: 42)
        let touch = UITouch(at: pos0, in: mockView, touchId: 0)

        pgr.touchesBegan([touch], with: UIEvent())
        XCTAssert(pgr.state == .began)

        let pos1 = CGPoint(x: 23, y: 21)
        touch.updatePositionInView(pos1)
        pgr.touchesMoved([touch], with: UIEvent())
        XCTAssert(pgr.state == .changed)


        pgr.touchesCancelled([touch], with: UIEvent())

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

        let touch = UITouch(at: .zero, in: mockView, touchId: 0)
        pgr.touchesBegan([touch], with: UIEvent())

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeInterval) {
            touch.updatePositionInView(CGPoint(x: touchPositionDiff, y: 0))
            pgr.touchesMoved([touch], with: UIEvent())
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
        let touch = UITouch(at: touchPosition0, in: view, touchId: 0)
        pgr.touchesBegan([touch], with: UIEvent())
        XCTAssertEqual(pgr.translation(in: view), touchPosition0)

        // move touch, translation should be equal to touch position
        touch.updatePositionInView(touchPosition1)
        pgr.touchesMoved([touch], with: UIEvent())
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
        let isInRange = (min ..< max)~=(Double(self))
        if !isInRange { print("$(self) is not in range of $(value)") }
        return isInRange
    }
}
