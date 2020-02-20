//
//  UIView+subviews.swift
//  UIKit
//
//  Created by Geordie Jay on 23.01.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import XCTest

class UIViewSubviewTests: XCTestCase {
    func testSubviewsAndSublayersInitiallyEmpty() {
        let view = UIView()

        XCTAssertEqual(view.subviews, [])
        XCTAssert(view.layer.sublayers == nil)
    }

    func testAddSubview() {
        let view = UIView()
        let subview = UIView()

        view.addSubview(subview)

        XCTAssertEqual(subview.superview, view)
        XCTAssertEqual(subview.layer.superlayer, view.layer)

        XCTAssertEqual(view.subviews, [subview])

        guard let sublayers = view.layer.sublayers else {
            return XCTFail("A view should have sublayers after adding a subview to it")
        }

        XCTAssertEqual(sublayers, [subview.layer])
    }

    func testRemoveFromSuperview() {
        let view = UIView()
        let subview = UIView()

        view.addSubview(subview)
        subview.removeFromSuperview()

        XCTAssertEqual(view.superview, nil)
        XCTAssertEqual(view.layer.superlayer, nil)

        XCTAssert(view.subviews.isEmpty)
        XCTAssertNil(view.layer.sublayers)
    }


    func testAddTwoSubviews() {
        let view = UIView()
        let subview1 = UIView()
        let subview2 = UIView()

        view.addSubview(subview1)
        view.addSubview(subview2)

        XCTAssertEqual(view.subviews, [subview1, subview2])
        XCTAssertEqual(view.layer.sublayers!, [subview1.layer, subview2.layer])
    }

    func testInsertSubviewAtIndex() {
        let view = UIView()
        let subview1 = UIView()
        let subview2 = UIView()
        let subview3 = UIView()

        view.addSubview(subview1)
        view.addSubview(subview2)
        view.insertSubview(subview3, at: 1)

        XCTAssertEqual(view.subviews, [subview1, subview3, subview2])
        XCTAssertEqual(view.layer.sublayers!, [subview1.layer, subview3.layer, subview2.layer])
    }

    func testInsertSubviewAboveNonExistentSibling() {
        let view = UIView()
        let subview1 = UIView()
        let subview2 = UIView()
        let subview3 = UIView()
        let notASubview = UIView()

        view.addSubview(subview1)
        view.addSubview(subview2)
        view.insertSubview(subview3, belowSubview: notASubview)

        XCTAssertEqual(view.subviews, [subview1, subview2, subview3])
        XCTAssertEqual(view.layer.sublayers!, [subview1.layer, subview2.layer, subview3.layer])
    }


    func testAddTwoSubviewsWithLayerInBetween() {
        let view = UIView()
        let sublayer = CALayer()
        let subview1 = UIView()
        let subview2 = UIView()

        view.addSubview(subview1)
        view.layer.addSublayer(sublayer)
        view.addSubview(subview2)

        XCTAssertEqual(view.subviews, [subview1, subview2])
        XCTAssertEqual(view.layer.sublayers!, [subview1.layer, sublayer, subview2.layer])
    }


    func testInsertSubviewAboveWithLayerInBetween() {
        let view = UIView()
        let sublayer = CALayer()
        let subview1 = UIView()
        let subview2 = UIView()

        view.addSubview(subview1)
        view.layer.addSublayer(sublayer)
        view.insertSubview(subview2, aboveSubview: subview1)

        XCTAssertEqual(view.subviews, [subview1, subview2])
        XCTAssertEqual(view.layer.sublayers!, [subview1.layer, subview2.layer, sublayer])
    }


    func testInsertSubviewBelowWithLayerInBetween() {
        let view = UIView()
        let sublayer = CALayer()
        let subview1 = UIView()
        let subview2 = UIView()

        view.addSubview(subview1)
        view.layer.addSublayer(sublayer)
        view.insertSubview(subview2, belowSubview: subview1)

        XCTAssertEqual(view.subviews, [subview2, subview1])
        XCTAssertEqual(view.layer.sublayers!, [subview2.layer, subview1.layer, sublayer])
    }


    func testInsertSubviewBelowWithLayerAtBottom() {
        let view = UIView()
        let sublayer = CALayer()
        let subview1 = UIView()
        let subview2 = UIView()

        view.layer.addSublayer(sublayer)
        view.addSubview(subview1)
        view.insertSubview(subview2, belowSubview: subview1)

        XCTAssertEqual(view.subviews, [subview2, subview1])
        XCTAssertEqual(view.layer.sublayers!, [sublayer, subview2.layer, subview1.layer])
    }


    func testInsertSubviewBelowWithLayerDirectlyBelow() {
        let view = UIView()
        let sublayer = CALayer()
        let subview1 = UIView()
        let subview2 = UIView()
        let subview3 = UIView()

        view.addSubview(subview1)
        view.layer.addSublayer(sublayer)
        view.addSubview(subview2)
        view.insertSubview(subview3, belowSubview: subview2)

        // subview3's layer should now be below subview2's but above `sublayer`
        XCTAssertEqual(view.subviews, [subview1, subview3, subview2])
        XCTAssertEqual(view.layer.sublayers!, [subview1.layer, sublayer, subview3.layer, subview2.layer])
    }


    func testDidMoveToSuperview() {
        class TestView: UIView {
            static var didMoveToSuperviewWasCalled = false
            override func didMoveToSuperview() {
                TestView.didMoveToSuperviewWasCalled = true
            }
        }

        let view = UIView()
        let subview = TestView()

        view.addSubview(subview)
        XCTAssertTrue(TestView.didMoveToSuperviewWasCalled)

        TestView.didMoveToSuperviewWasCalled = false

        subview.removeFromSuperview()
        XCTAssertTrue(TestView.didMoveToSuperviewWasCalled)
    }

    func testInsertSubviewAtUnrealisticIndex() {
        let view = UIView()
        let subview = UIView()

        view.insertSubview(subview, at: 999)
        XCTAssertEqual(view.subviews, [subview])
    }

    func testInsertSublayerAtUnrealisticIndex() {
        let layer = CALayer()
        let anotherLayer = CALayer()

        layer.insertSublayer(anotherLayer, at: 999)

        XCTAssertEqual(layer.sublayers?.last, anotherLayer)
    }

    func testAddSublayerMultipleTimes() {
        let layer = CALayer()
        let anotherLayer = CALayer()

        layer.addSublayer(anotherLayer)
        layer.addSublayer(anotherLayer)

        XCTAssertEqual(layer.sublayers?.count, 1)
        XCTAssertEqual(layer.sublayers?.first, anotherLayer)
    }
}
