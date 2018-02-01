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
    private var testCallbackWasCalled = false

    override func setUp() {
        view = UIView()
        subview = TestView()
        testCallbackWasCalled = false
    }

    private func sublayerHasBeenInserted() -> Bool {
        return (self.view.layer.sublayers?.contains(self.subview.layer)) ?? false
    }

    func testInsertLayerBeforeDidMoveToSuperViewWasCalledWhenAddingSubviews() {
        subview.onDidMoveToSuperView = {
            XCTAssertTrue(self.sublayerHasBeenInserted())
            self.testCallbackWasCalled = true
        }

        view.addSubview(subview)

        XCTAssertTrue(testCallbackWasCalled)
    }

    func testInsertLayerBeforeDidMoveToSuperViewWasCalledWhenInsertingSubviewsAtIndex() {
        subview.onDidMoveToSuperView = {
            XCTAssertTrue(self.sublayerHasBeenInserted())
            self.testCallbackWasCalled = true
        }

        view.insertSubview(subview, at: 0)

        XCTAssertTrue(testCallbackWasCalled)
    }

    func testInsertLayerBeforeDidMoveToSuperViewWasCalledWhenInsertingAboveSubview() {
        subview.onDidMoveToSuperView = {
            XCTAssertTrue(self.sublayerHasBeenInserted())
            self.testCallbackWasCalled = true
        }

        view.insertSubview(subview, aboveSubview: view)

        XCTAssertTrue(testCallbackWasCalled)
    }

    func testInsertLayerBeforeDidMoveToSuperViewWasCalledWhenInsertingBelowSubview() {
        subview.onDidMoveToSuperView = {
            XCTAssertTrue(self.sublayerHasBeenInserted())
            self.testCallbackWasCalled = true
        }

        view.insertSubview(subview, belowSubview: view)

        XCTAssertTrue(testCallbackWasCalled)
    }

}

fileprivate class TestView: UIView {
    var onDidMoveToSuperView: (() -> Void)?
    override func didMoveToSuperview() {
        onDidMoveToSuperView?()
    }
}
