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

    override public var state: UIGestureRecognizerState {
        didSet {
            switch state {
            case .ended: stateEndedExpectation?.fulfill()
            case .cancelled: stateCancelledExpectation?.fulfill()
            default: break
            }
        }
    }

    fileprivate init (cancelledExp: XCTestExpectation? = nil, endedExp: XCTestExpectation? = nil){
        stateCancelledExpectation = cancelledExp
        stateEndedExpectation = endedExp
    }
}

class UIGestureRegognizerTests: XCTestCase {
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
        wait(for: [endedExpectation], timeout: 1)
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
        wait(for: [cancelledExpectation], timeout: 1)
        XCTAssert(pgr.state == .possible)
    }

    func testPanGestureVelocity () {
        let touchPositionDiff: CGFloat = 50
        let timeInterval = 1.0

        let pgr = UIPanGestureRecognizer()
        let velocityExp = expectation(description: "velocity is as expected")

        pgr.touchesBegan([mockTouch], with: UIEvent())
        self.mockTouch.positionInView = CGPoint(x: touchPositionDiff, y: 0)
        pgr.touchesMoved([self.mockTouch], with: UIEvent())
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeInterval) {
            self.mockTouch.positionInView = CGPoint(
                x: self.mockTouch.positionInView.x + touchPositionDiff,
                y: self.mockTouch.positionInView.y
            )
            pgr.touchesMoved([self.mockTouch], with: UIEvent())
            let velocityX = pgr.velocity(in: self.mockView).x
            let expectedVelocityX: CGFloat = touchPositionDiff / CGFloat(timeInterval)

            print(velocityX, expectedVelocityX)
            if velocityX.isRoundAbout(to: expectedVelocityX, percentalAccuracy: 5.0) {
                velocityExp.fulfill()
            }
        }

        wait(for: [velocityExp], timeout: 1.1)
    }
}

fileprivate extension CGFloat {
    func isRoundAbout(to value: CGFloat, percentalAccuracy: Double) -> Bool {
        let min = Double(value) - ((Double(value) * percentalAccuracy) / 100)
        let max = Double(value) + ((Double(value) * percentalAccuracy) / 100)
        return  (min ..< max)~=(Double(self)) // if in range
    }
}
