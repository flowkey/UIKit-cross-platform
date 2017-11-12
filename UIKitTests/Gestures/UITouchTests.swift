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

        let position = CGPoint(x: 30, y: 30)
        touch.positionInView = position

        XCTAssertEqual(touch.location(in: view), position)
        XCTAssertEqual(touch.location(in: nil), position)
    }



    /*
     * ToDo: add tests where the views bounds are changed
     */

}
