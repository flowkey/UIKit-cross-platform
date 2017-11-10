//
//  UITouchTests.swift
//  UIKitTests
//
//  Created by flowing erik on 10.11.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

class UITouchTests: XCTestCase {

    func testLocationInView() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        let touch = UITouch(at: .zero, in: view, touchId: 0)

        XCTAssertEqual(touch.location(in: view), .zero)

        let position = CGPoint(x: 30, y: 30)
        touch.positionInView = position

        XCTAssertEqual(touch.location(in: view), position)
        XCTAssertEqual(touch.location(in: nil), position)
    }

    func testLocationInOtherView() {
        let view = UIView(frame: CGRect(x: 15, y: 15, width: 50, height: 50))
        let position = CGPoint(x: 30, y: 30)
        let touch = UITouch(at: position, in: view, touchId: 0)

        XCTAssertEqual(touch.location(in: view), position)

        let otherView = UIView(frame: CGRect(x: 20, y: 20, width: 50, height: 50))
        let expectedLocationInOtherView = CGPoint(
            x: 25,
            y: 25
        )
        XCTAssertEqual(touch.location(in: otherView), expectedLocationInOtherView)
    }

    /*
     * Should we add more tests where the views bounds are changed?
     * I'm not sure what role they play here
     */

}
