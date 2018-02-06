//
//  UIViewTests.swift
//  UIKitTests
//
//  Created by Geordie Jay on 16.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

class UIViewTests: XCTestCase {
    /*  (0,0, width: 100, height: 100):
     --------------------------
     1. (20, 10):
         ---
         |1|
         ---
     

              2. (80, 80):
                      ----
                      |  |
                      |  |
                      ----
     --------------------------
    */
    func testPointConversion() {
        let rootView = UIView()
        rootView.bounds = CGRect(x: 0, y: 0, width: 100, height: 100)

        let subview1 = UIView()
        subview1.frame = CGRect(x: 20, y: 10, width: 10, height: 10)

        let subview2 = UIView()
        subview2.frame = CGRect(x: 80, y: 80, width: 20, height: 20)

        rootView.addSubview(subview1)
        rootView.addSubview(subview2)


        // Basic case
        // These two should be testing the same thing
        // Note: `bounds.origin` defaults to (0,0)...
        XCTAssertEqual(rootView.convert(subview1.bounds.origin, from: subview1), subview1.frame.origin)
        XCTAssertEqual(subview1.convert(subview1.bounds.origin, to: rootView), subview1.frame.origin)


        // Slightly more involved cases:
        XCTAssertEqual(rootView.convert(CGPoint(x: 15, y: 15), to: subview1), CGPoint(x: -5, y: 5))
        XCTAssertEqual(subview1.convert(CGPoint(x: 5, y: 5), to: rootView), CGPoint(x: 25, y: 15))

        XCTAssertEqual(rootView.convert(CGPoint(x: 85, y: 85), to: subview2), CGPoint(x: 5, y: 5))
        XCTAssertEqual(subview2.convert(CGPoint(x: -5, y: -5), to: rootView), CGPoint(x: 75, y: 75))


        // Even more involved cases:
        XCTAssertEqual(subview1.convert(CGPoint(x: 60, y: 70), to: subview2), CGPoint(x: 0, y: 0))
        XCTAssertEqual(subview2.convert(CGPoint(x: -5, y: -5), to: subview1), CGPoint(x: 55, y: 65))

        let subSubView = UIView(frame: CGRect(x: 5, y: 5, width: 5, height: 5))
        subview2.addSubview(subSubView)

        XCTAssertEqual(subSubView.convert(CGPoint(x: 1, y: 1), to: subview1), CGPoint(x: 66, y: 76))
    }

    func testAbsoluteOrigin() {
        let rootView = UIView()
        rootView.bounds = CGRect(x: 15, y: -5, width: 100, height: 100)

        let subview1 = UIView()
        subview1.frame = CGRect(x: 20, y: 10, width: 10, height: 10)

        let subview1subview1 = UIView()
        subview1subview1.frame = CGRect(x: 5, y: 5, width: 5, height: 5)

        rootView.addSubview(subview1)
        subview1.addSubview(subview1subview1)

        XCTAssertEqual(rootView.absoluteOrigin(), CGPoint(x: 0, y: 0))
        XCTAssertEqual(subview1subview1.absoluteOrigin(), CGPoint(x: 10, y: 20))
    }

    func testPointInside() {
        let view = UIView()
        // bounds.origin affect child elements only
        view.bounds = CGRect(x: 100000, y: 100000, width: 100, height: 100)
        XCTAssertTrue((view.point(inside: CGPoint(x: 99, y: 99), with: nil)))
        XCTAssertFalse((view.point(inside: CGPoint(x: 100, y: 100), with: nil)))
    }

    func testHitTest() {
        let rootView = UIView()
        rootView.bounds = CGRect(x: -10, y: -10, width: 100, height: 100)

        let subview1 = UIView()
        subview1.frame = CGRect(x: 40, y: 40, width: 20, height: 20)

        let subview1subview1 = UIView()
        subview1subview1.frame = CGRect(x: 10, y: 10, width: 5, height: 5)

        rootView.addSubview(subview1)
        subview1.addSubview(subview1subview1)

        XCTAssertEqual(rootView.hitTest(CGPoint(x: 0, y: 0), with: nil), rootView)
        XCTAssertEqual(rootView.hitTest(CGPoint(x: 50, y: 50), with: nil), subview1)
        XCTAssertEqual(rootView.hitTest(CGPoint(x: 62.5, y: 62.5), with: nil), subview1subview1)
        XCTAssertNil(rootView.hitTest(CGPoint(x: -1, y: -1), with: nil))
    }

    func testNeedsLayoutDefaultTrue() {
        class ParentView: UIView {
            override func layoutSubviews() {
                super.layoutSubviews()
                for view in subviews { view.frame.size = CGSize(width: 300, height: 100) }
            }
        }
        let parentView = ParentView()
        let subview = UIView(frame: .zero)
        parentView.addSubview(subview)
        parentView.layoutIfNeeded()

        XCTAssertEqual(subview.frame.width, 300)
        XCTAssertEqual(subview.frame.height, 100)
    }

    func testPreventStrongReferenceCyclesBetweenSubviews() {
        var view: UIView? = .init()
        var subview: UIView? = .init()
        view?.addSubview(subview!)
        weak var weakViewReference = view
        weak var weakSubviewReference = subview

        view = nil
        subview = nil

        XCTAssertNil(weakViewReference)
        XCTAssertNil(weakSubviewReference)
    }

}
