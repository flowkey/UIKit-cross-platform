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
    private var anotherView = TestView()
    private var testCallBackWasCalled = false

    override func setUp() {
        view = UIView()
        anotherView = TestView()
        testCallBackWasCalled = false
    }

    private func sublayerHasBeenInserted() -> Bool {
        return (self.view.layer.sublayers?.contains(self.anotherView.layer)) ?? false
    }

    func testInsertLayerBeforeDidMoveToSuperViewWasCalledWhenAddingSubviews() {
        anotherView.onDidMoveToSuperView = {
            XCTAssertTrue(self.sublayerHasBeenInserted())
            self.testCallBackWasCalled = true
        }

        view.addSubview(anotherView)

        XCTAssertTrue(testCallBackWasCalled)
    }

    func testInsertLayerBeforeDidMoveToSuperViewWasCalledWhenInsertingSubviewsAtIndex() {
        anotherView.onDidMoveToSuperView = {
            XCTAssertTrue(self.sublayerHasBeenInserted())
            self.testCallBackWasCalled = true
        }

        view.insertSubview(anotherView, at: 0)

        XCTAssertTrue(testCallBackWasCalled)
    }

    func testInsertLayerBeforeDidMoveToSuperViewWasCalledWhenInsertingAboveSubview() {
        anotherView.onDidMoveToSuperView = {
            XCTAssertTrue(self.sublayerHasBeenInserted())
            self.testCallBackWasCalled = true
        }

        view.insertSubview(anotherView, aboveSubview: view)

        XCTAssertTrue(testCallBackWasCalled)
    }

    func testInsertLayerBeforeDidMoveToSuperViewWasCalledWhenInsertingBelowSubview() {
        anotherView.onDidMoveToSuperView = {
            XCTAssertTrue(self.sublayerHasBeenInserted())
            self.testCallBackWasCalled = true
        }

        view.insertSubview(anotherView, belowSubview: view)

        XCTAssertTrue(testCallBackWasCalled)
    }

}

fileprivate class TestView: UIView {
    var onDidMoveToSuperView: (() -> Void)?
    override func didMoveToSuperview() {
        onDidMoveToSuperView?()
    }
}
