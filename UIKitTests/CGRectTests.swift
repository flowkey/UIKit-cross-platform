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

    func testIntersectionIsCommutative() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 100)
        let b = CGRect(x: 25, y: 25, width: 50, height: 50)

        let intersectionA = a.intersection(b)
        let intersectionB = b.intersection(a)

        XCTAssertEqual(intersectionA, intersectionB)
    }

    func testIntersectionWithConcentricRects() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 100)
        let b = CGRect(x: 25, y: 25, width: 50, height: 50)

        let intersection = a.intersection(b)

        XCTAssertEqual(intersection, CGRect(x: 25, y: 25, width: 50, height: 50))
    }

    func testIntersectionWithPartiallyOverlappingRects() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 100)
        let b = CGRect(x: 75, y: 75, width: 50, height: 50)

        let intersection = a.intersection(b)

        XCTAssertEqual(intersection, CGRect(x: 75, y: 75, width: 25, height: 25))
    }

    func testIntersectionWithNoOverlap() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 100)
        let b = CGRect(x: 125, y: 125, width: 50, height: 50)

        let intersection = a.intersection(b)

        XCTAssert(intersection.isNull)
    }
}

