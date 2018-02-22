//
//  UIViewHitTests
//  UIKitTests
//
//  Created by Geordie Jay on 16.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest

class UIViewHitTests: XCTestCase {
    func testPointInside() {
        let view = UIView()
        view.bounds.size = CGSize(width: 100, height: 100)
        XCTAssertTrue((view.point(inside: CGPoint(x: 99, y: 99), with: nil)))
        XCTAssertFalse((view.point(inside: CGPoint(x: 100, y: 100), with: nil)))
    }

    // `point(inside:)` is in `bounds` units and therefore *is* affected by bounds.origin
    func testPointInsideWithBoundsOriginSet() {
        let view = UIView()
        view.bounds.size = CGSize(width: 100, height: 100)
        view.bounds.origin = CGPoint(x: 10000, y: 10000)
        XCTAssertFalse((view.point(inside: CGPoint(x: 50, y: 50), with: nil)))
    }

    func testHitTest() {
        let rootView = UIView()
        rootView.bounds = CGRect(x: -10, y: -10, width: 100, height: 100)
        rootView.frame.origin = .zero

        let subview1 = UIView()
        subview1.frame = CGRect(x: 40, y: 40, width: 20, height: 20)

        let subview1subview1 = UIView()
        subview1subview1.frame = CGRect(x: 10, y: 10, width: 5, height: 5)

        rootView.addSubview(subview1)
        subview1.addSubview(subview1subview1)

        XCTAssertEqual(rootView.hitTest(CGPoint(x: -5, y: -5), with: nil), rootView)
        XCTAssertEqual(rootView.hitTest(CGPoint(x: 40, y: 40), with: nil), subview1)
        XCTAssertEqual(rootView.hitTest(CGPoint(x: 52.5, y: 52.5), with: nil), subview1subview1)

        // These are outside the bounds rect
        XCTAssertNil(rootView.hitTest(CGPoint(x: -11, y: -11), with: nil))
        XCTAssertNil(rootView.hitTest(CGPoint(x: 95, y: 95), with: nil))
    }
}
