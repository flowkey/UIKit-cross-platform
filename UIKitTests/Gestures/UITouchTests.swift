//
//  UITouchTests.swift
//  UIKitTests
//
//  Created by flowing erik on 10.11.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

@MainActor
class UITouchTests: XCTestCase {
    func testLocationInView() {
        let window = UIWindow()
        window.frame.size = CGSize(width: 800, height: 300)

        let rootView = UIView()
        let view = UIView(frame: CGRect(x: 10, y: 10, width: 50, height: 50))

        rootView.addSubview(view)

        let touch = UITouch(touchId: 0, at: CGPoint(x: 10, y: 10), timestamp: 0)
        touch.window = window

        // touch location in view should always be in bounds units.
        XCTAssertEqual(touch.location(in: view), .zero)

        let location = CGPoint(x: 30, y: 30)
        touch.updateAbsoluteLocation(location)

        XCTAssertEqual(touch.location(in: view), location - view.absoluteOrigin())
        XCTAssertEqual(touch.location(in: nil), location)
    }

    
    func testLocationInNilReturnsAbsoluteLocation() {
        let point = CGPoint(x: 10, y: 10)

        let touch = UITouch(touchId: 0, at: point, timestamp: 0)
        XCTAssertEqual(touch.location(in: nil), point)
    }

    /*
     * ToDo: add tests where the views bounds are changed
     */
}
