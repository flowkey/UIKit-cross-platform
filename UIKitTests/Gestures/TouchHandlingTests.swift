//
//  TouchHandlingTests.swift
//  UIKitTests
//
//  Created by flowing erik on 13.11.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

class TouchHandlingTests: XCTestCase {
    override static func setUp() {
        SDL.rootView = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 1000, height: 1000)))
    }

//    func testSimpleTouchdown() {
//        XCTAssertEqual(UITouch.activeTouches.count, 0)
//        SDL.handleTouchDown(.zero)
//        XCTAssertEqual(UITouch.activeTouches.count, 1)
//    }
//
//    func testSimpleTouchMove() {
//        let activeTouch = UITouch(at: CGPoint(x: 10, y: 10), touchId: 0)
//        UITouch.activeTouches = [ activeTouch ]
//        let newPosition = CGPoint(x: 20, y: 20)
//        SDL.handleTouchMove(newPosition)
//        XCTAssertEqual(activeTouch.location(in: nil), newPosition)
//    }
//
//    func testSimpleTouchUp() {
//        let activeTouch = UITouch(at: CGPoint(x: 10, y: 10), touchId: 0)
//        UITouch.activeTouches = [ activeTouch ]
//        let touchUpPosition = CGPoint(x: 20, y: 20)
//        SDL.handleTouchUp(touchUpPosition)
//        XCTAssertEqual(UITouch.activeTouches.count, 0)
//    }
}
