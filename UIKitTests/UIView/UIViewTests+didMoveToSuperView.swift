//
//  UIViewTests+didMoveToSuperView.swift
//  UIKitTests
//
//  Created by Michael Knoch on 31.01.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import UIKit
import XCTest

class UIViewDidMoveToSuperViewTests: XCTestCase {
    private var view = UIView()
    private var subview = TestView()
    private var testCallBackWasCalled = false

    override func setUp() {
        view = UIView()
        subview = TestView()
        testCallBackWasCalled = false
    }

    private func sublayerHasBeenInserted() -> Bool {
        return (self.view.layer.sublayers?.contains(self.subview.layer)) ?? false
    }

    func testInsertLayerBeforeDidMoveToSuperViewWasCalledWhenAddingSubviews() {
        subview.onDidMoveToSuperView = {
            XCTAssertTrue(self.sublayerHasBeenInserted())
            self.testCallBackWasCalled = true
        }

        view.addSubview(subview)

        XCTAssertTrue(testCallBackWasCalled)
    }

    func testInsertLayerBeforeDidMoveToSuperViewWasCalledWhenInsertingSubviewsAtIndex() {
        subview.onDidMoveToSuperView = {
            XCTAssertTrue(self.sublayerHasBeenInserted())
            self.testCallBackWasCalled = true
        }

        view.insertSubview(subview, at: 0)

        XCTAssertTrue(testCallBackWasCalled)
    }

    func testInsertLayerBeforeDidMoveToSuperViewWasCalledWhenInsertingAboveSubview() {
        subview.onDidMoveToSuperView = {
            XCTAssertTrue(self.sublayerHasBeenInserted())
            self.testCallBackWasCalled = true
        }

        view.insertSubview(subview, aboveSubview: view)

        XCTAssertTrue(testCallBackWasCalled)
    }

    func testInsertLayerBeforeDidMoveToSuperViewWasCalledWhenInsertingBelowSubview() {
        subview.onDidMoveToSuperView = {
            XCTAssertTrue(self.sublayerHasBeenInserted())
            self.testCallBackWasCalled = true
        }

        view.insertSubview(subview, belowSubview: view)

        XCTAssertTrue(testCallBackWasCalled)
    }

}

fileprivate class TestView: UIView {
    var onDidMoveToSuperView: (() -> Void)?
    override func didMoveToSuperview() {
        onDidMoveToSuperView?()
    }
}
