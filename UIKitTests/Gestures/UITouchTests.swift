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
        let view = UIView(frame: CGRect(x: 10, y: 10, width: 50, height: 50))
        let touch = UITouch(at: .zero, in: view, touchId: 0)

        XCTAssertEqual(touch.location(in: view), .zero)

        let location = CGPoint(x: 30, y: 30)
        touch.updateLocationInView(location)

        XCTAssertEqual(touch.location(in: view), location)
        XCTAssertEqual(touch.location(in: nil), location)
    }


    func testLocationInOtherView() {
        let touchLocation = CGPoint(x: 30, y: 30)
        let view = UIView(frame: CGRect(x: 50, y: 50, width: 50, height: 50))
        let touch = UITouch(at: touchLocation, in: view, touchId: 0)

        XCTAssertEqual(touch.location(in: view), touchLocation)

        let otherView = UIView(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
        let expectedLocationInOtherView = CGPoint(
            x: -20,
            y: -20
        )
        XCTAssertEqual(touch.location(in: otherView), expectedLocationInOtherView)
    }

    /*
     * ToDo: add tests where the views bounds are changed
     */
}
