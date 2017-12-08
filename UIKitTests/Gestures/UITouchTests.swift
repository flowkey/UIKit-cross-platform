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

    /*
     * ToDo: add tests where the views bounds are changed
     */
}
