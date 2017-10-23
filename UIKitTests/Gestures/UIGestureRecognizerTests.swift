//
//  UIGestureRecognizerTests.swift
//  UIKitTests
//
//  Created by flowing erik on 23.10.17.
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

class UIGestureRecognizerTests: XCTestCase {

    var mockTouch: UITouch!
    let mockView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))

    override func setUp() {
        mockTouch = UITouch(
            at: CGPoint(x: 0, y: 0),
            in: mockView,
            touchId: 0
        )
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
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
}
