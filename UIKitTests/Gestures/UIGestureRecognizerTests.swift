//
//  UIGestureRecognizerTests.swift
//  UIKitTests
//
//  Created by flowing erik on 22.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

class TestPanGestureRecognizer: UIPanGestureRecognizer {
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
    override func setUp() {
        mockTouch = UITouch(
            at: CGPoint(x: 0, y: 0),
            in: UIView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100))),
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
        XCTAssert(pgr.state == .possible)  // XXX: state is set to .ended and then immediately resetted to .possible
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
}
