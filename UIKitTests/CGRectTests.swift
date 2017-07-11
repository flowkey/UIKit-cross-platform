//
//  CGRectTests.swift
//  UIKitTests
//
//  Created by Geordie Jay on 10.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
import UIKit

typealias CGRect = UIKit.CGRect

class CGRectTests: XCTestCase {
    func testRectsIntersectSimple() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 100)
        let b = CGRect(x: 50, y: 50, width: 100, height: 100)

        XCTAssert(a.intersects(b))
        XCTAssert(b.intersects(a))
    }

    func testRectsDontIntersectSimple() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 100)
        let b = CGRect(x: 150, y: 150, width: 100, height: 100)

        XCTAssert(!a.intersects(b))
        XCTAssert(!b.intersects(a))
    }


    func testRectsIntersectHorizontal() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 100)
        let b = CGRect(x: 50, y: 0, width: 100, height: 100)

        XCTAssert(a.intersects(b))
        XCTAssert(b.intersects(a))
    }

    func testRectsDontIntersectHorizontal() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 100)
        let b = CGRect(x: 150, y: 0, width: 100, height: 100)

        XCTAssert(!a.intersects(b))
        XCTAssert(!b.intersects(a))
    }


    func testRectsIntersectVertical() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 100)
        let b = CGRect(x: 0, y: 50, width: 100, height: 100)

        XCTAssert(a.intersects(b))
        XCTAssert(b.intersects(a))
    }

    func testRectsDontIntersectVertical() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 100)
        let b = CGRect(x: 0, y: 150, width: 100, height: 100)

        XCTAssert(!a.intersects(b))
        XCTAssert(!b.intersects(a))
    }


    func testRectsIntersectComplex() {
        let a = CGRect(x: 3, y: -10, width: 100, height: 100)
        let b = CGRect(x: 50, y: -30, width: 100, height: 100)

        XCTAssert(a.intersects(b))
        XCTAssert(b.intersects(a))
    }


    func testRectsIntersectConcentric() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 100)
        let b = CGRect(x: 25, y: 25, width: 50, height: 50)

        XCTAssert(a.intersects(b))
        XCTAssert(b.intersects(a))
    }
}

