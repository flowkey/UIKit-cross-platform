//
//  UIViewPointConversionTests
//  UIKitTests
//
//  Created by Geordie Jay on 21.02.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
#if !os(iOS)
@testable import UIKit
#endif

@MainActor
class UIViewPointConversionTests: XCTestCase {
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
        let subview1 = UIView()
        let subview1subview1 = UIView()

        subview1.frame = CGRect(x: 10, y: 10, width: 10, height: 10)
        subview1subview1.frame = CGRect(x: 5, y: 5, width: 5, height: 5)

        rootView.addSubview(subview1)
        subview1.addSubview(subview1subview1)

        XCTAssertEqual(subview1subview1.absoluteOrigin(), CGPoint(x: 15, y: 15))
    }

    func testAbsoluteOriginWithNonZeroRootViewBounds() {
        let rootView = UIView()
        let subview1 = UIView()
        let subview1subview1 = UIView()

        rootView.bounds = CGRect(x: 10, y: 10, width: 100, height: 100) // non-zero bounds
        rootView.frame.origin = .zero // without this frame will be different according to its position
        subview1.frame = CGRect(x: 20, y: 20, width: 10, height: 10)
        subview1subview1.frame = CGRect(x: 5, y: 5, width: 5, height: 5)

        rootView.addSubview(subview1)
        subview1.addSubview(subview1subview1)

        XCTAssertEqual(subview1subview1.absoluteOrigin(), CGPoint(x: 25, y: 25))
    }

    func testAbsoluteOriginWithNonZeroSubViewBounds() {
        let rootView = UIView()
        let subview1 = UIView(frame: CGRect(x: 20, y: 20, width: 10, height: 10))
        subview1.bounds.origin = CGPoint(x: 10, y: 10) // non-zero bounds
        rootView.addSubview(subview1)

        let subview1subview1 = UIView(frame: CGRect(x: 5, y: 5, width: 5, height: 5))
        subview1.addSubview(subview1subview1)

        XCTAssertEqual(subview1subview1.absoluteOrigin(), CGPoint(x: 15, y: 15))
    }

    func testAbsoluteOriginWithMultipleNonZeroBounds() {
        let rootView = UIView()
        rootView.bounds = CGRect(x: 10, y: 10, width: 100, height: 100)
        rootView.frame.origin = .zero

        let subview1 = UIView(frame: CGRect(x: 20, y: 20, width: 10, height: 10))
        subview1.bounds.origin = CGPoint(x: 5, y: 5)
        rootView.addSubview(subview1)

        let subview1subview1 = UIView(frame: CGRect(x: 5, y: 5, width: 5, height: 5))
        subview1subview1.bounds.origin = CGPoint(x: 999, y: 999) // definitely shouldn't have any effect
        subview1.addSubview(subview1subview1)

        XCTAssertEqual(subview1subview1.absoluteOrigin(), CGPoint(x: -979, y: -979))
    }


    func testAbsoluteOriginWithTransforms() {
        let rootView = UIView(frame: CGRect(x: 0, y: 0, width: 512, height: 512))

        let subview = UIView()
        subview.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        subview.frame = CGRect(x: 128, y: 128, width: 256, height: 256)
        subview.bounds.origin = CGPoint(x: 32, y: 32)
        rootView.addSubview(subview)

        let subviewSubview = UIView()
        subviewSubview.transform = CGAffineTransform(scaleX: 2, y: 2)
        subviewSubview.frame = CGRect(x: 128, y: 128, width: 128, height: 128)
        subview.addSubview(subviewSubview)

        XCTAssertEqual(subviewSubview.absoluteOrigin(), CGPoint(x: 176, y: 176))
    }

    func testAbsoluteOriginWithTransformsAndLotsOfBounds() {
        let rootView = UIView(frame: CGRect(x: 0, y: 0, width: 512, height: 512))
        rootView.bounds.origin = CGPoint(x: 16, y: 18)

        let subview = UIView()
        subview.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        subview.frame = CGRect(x: 128, y: 128, width: 256, height: 256)
        subview.bounds.origin = CGPoint(x: 32, y: 32)
        rootView.addSubview(subview)

        // Without this the test would pass even with an incorrect implementation of absoluteOrigin
        // This ensures that the transforms affect subviews' subviews (etc.) too, and not just direct children:
        let blankSubview = UIView()
        subview.addSubview(blankSubview)

        let subviewSubview = UIView()
        subviewSubview.transform = CGAffineTransform(scaleX: 3, y: 3) // has no effect on absolute origin
        subviewSubview.frame = CGRect(x: 100, y: 128, width: 128, height: 128)
        subviewSubview.bounds.origin = CGPoint(x: 64, y: 32) // has no effect on absolute origin
        blankSubview.addSubview(subviewSubview)

        XCTAssertEqual(subviewSubview.absoluteOrigin(), CGPoint(x: 66, y: 128))
    }


    func testCoordinateSystemConversion() {
        let rootView = UIView()
        let subview1 = UIView()
        let subview1subview1 = UIView()

        subview1.frame = CGRect(x: 20, y: 20, width: 10, height: 10)
        subview1subview1.frame = CGRect(x: 5, y: 5, width: 5, height: 5)

        rootView.addSubview(subview1)
        subview1.addSubview(subview1subview1)

        let expectedPoint = CGPoint(x: 25, y: 25)
        XCTAssertEqual(expectedPoint, subview1subview1.absoluteOrigin())
        XCTAssertEqual(expectedPoint, rootView.convert(.zero, from: subview1subview1))
    }

    func testConvertWithNilView() {
        let rootView = UIView()
        let point = CGPoint(x: 10, y: 10)
        XCTAssertEqual(rootView.convert(point, to: nil), point)
        XCTAssertEqual(rootView.convert(point, from: nil), point)
    }

    func testConvertToSubviewWithSubviewTransform() {
        let testPoint = CGPoint(x: 60, y: 20)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 40))
        let subview = UIView()

        subview.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        subview.frame = CGRect(x: 10, y: 10, width: 60, height: 40)
        view.addSubview(subview)

        let result = view.convert(testPoint, to: subview)
        let expectedPoint = CGPoint(x: 25, y: 5) // post conversion is always in bounds units (without transform)

        XCTAssertEqual(result, expectedPoint)
    }

    // functionally and programatically the opposite of the test above
    func testConvertToSuperviewWithSelfTransform() {
        let testPoint = CGPoint(x: 25, y: 5)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 40))
        let subview = UIView()

        subview.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        subview.frame = CGRect(x: 10, y: 10, width: 60, height: 40)
        view.addSubview(subview)

        let result = subview.convert(testPoint, to: view)
        let expectedPoint = CGPoint(x: 60, y: 20) // post conversion is always in bounds units (without transform)

        XCTAssertEqual(result, expectedPoint)
    }

    func testConvertPointWithNonZeroBoundsOriginToSuperview() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.bounds.origin = CGPoint(x: 50, y: 50)

        let subview = UIView(frame: CGRect(x: 40, y: 40, width: 20, height: 20))
        view.addSubview(subview)

        let testPoint = CGPoint(x: 10, y: 10)
        subview.bounds.origin = CGPoint(x: 123, y: 123)

        let testPointIgnoringSubviewBoundsOrigin = CGPoint(
            x: subview.bounds.origin.x + testPoint.x,
            y: subview.bounds.origin.y + testPoint.y
        )

        let convertedPoint1 = subview.convert(testPointIgnoringSubviewBoundsOrigin, to: view)
        let convertedPoint2 = view.convert(testPointIgnoringSubviewBoundsOrigin, from: subview)

        XCTAssertEqual(convertedPoint1, convertedPoint2)
        XCTAssertEqual(convertedPoint1, CGPoint(x: 50, y: 50))
    }

    func testConversionWithMultipleSubviewsBounds() {
        let window = UIWindow(
            // frame.origin does not affect the calculations
            frame: CGRect(
                x: Int.random(in: 0 ..< 5),
                y: Int.random(in: 0 ..< 5),
                width: 256,
                height: 256
            )
        )

        // not relevant, becase we're looking in *window's* coordinates
        window.bounds.origin = CGPoint(x: Int.random(in: 0 ..< 5), y: Int.random(in:  0 ..< 5))

        // TODO: should not be relevant, but unfortunately it is in our UIKit
        // window.transform = .init(scaleX: 0.5, y: 0.5)

        let subview = UIView(frame: CGRect(x: 80, y: 80, width: 100, height: 100))
        subview.bounds.origin = .init(x: 15, y: 15)
        // subview.transform = .init(scaleX: 10, y: 10) // TODO: wrong behaviour in our UIKIt
        window.addSubview(subview)

        let subview2 = UIView(frame: CGRect(x: 70, y: 70, width: 100, height: 100))
        subview2.bounds.origin = .init(x: 25, y: 25)
        subview.addSubview(subview2)

        let subview3 = UIView(frame: CGRect(x: 50, y: 50, width: 100, height: 100))
        subview3.bounds.origin = .init(x: 64, y: 64)
        // subview3.transform = .init(scaleX: 0.5, y: 0.5) // TODO: wrong behaviour in our UIKIt
        subview2.addSubview(subview3)

        let convertedPoint = subview3.convert(CGPoint(x: 20, y: 10), to: window)
        XCTAssertEqual(convertedPoint, CGPoint(x: 116, y: 106))
    }
}

#if os(iOS)
    extension CGPoint {
        static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
            return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
        }

        static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
            return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
        }
    }

    extension UIView {
        // XXX: we shouldn't actually need this function. It should be the same as running
        // `convert(self.bounds.origin, to: rootView)` or `to: touch.window)` etc.

        /// Returns `self.frame.origin` in `window.bounds` coordinates
        internal func absoluteOrigin() -> CGPoint {
            let rootView = self.getRootView()
            return convert(.zero, to: rootView)
        }

        func getRootView() -> UIView? {
            var currentView: UIView = self
            while let superview = currentView.superview {
                currentView = superview
            }

            return currentView
        }
    }
#endif
