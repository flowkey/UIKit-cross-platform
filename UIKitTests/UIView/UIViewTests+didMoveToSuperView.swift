//
//  UIViewTests+didMoveToSuperView.swift
//  UIKitTests
//
//  Created by Michael Knoch on 31.01.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import XCTest

class UIViewDidMoveToSuperViewTests: XCTestCase {
    private var view = UIView()
    private var subview = TestView()
    private var onDidMoveToSuperViewWasCalled = false

    override func setUp() {
        view = UIView()
        subview = TestView()
        onDidMoveToSuperViewWasCalled = false

        subview.onDidMoveToSuperView = {
            XCTAssertEqual(self.subview.layer.superlayer, self.view.layer)
            self.onDidMoveToSuperViewWasCalled = true
        }
    }
  
    func testLayersAreInsertedWhenDidMoveToSuperviewWasCalledOnAddSubview() {
        view.addSubview(subview)

        XCTAssertTrue(onDidMoveToSuperViewWasCalled)
    }

    func testInsertLayerBeforeDidMoveToSuperViewWasCalledWhenInsertingSubviewsAtIndex() {
        view.insertSubview(subview, at: 0)

        XCTAssertTrue(onDidMoveToSuperViewWasCalled)
    }

    func testInsertLayerBeforeDidMoveToSuperViewWasCalledWhenInsertingAboveSubview() {
        view.insertSubview(subview, aboveSubview: view)

        XCTAssertTrue(onDidMoveToSuperViewWasCalled)
    }

    func testInsertLayerBeforeDidMoveToSuperViewWasCalledWhenInsertingBelowSubview() {
        view.insertSubview(subview, belowSubview: view)

        XCTAssertTrue(onDidMoveToSuperViewWasCalled)
    }
}

fileprivate class TestView: UIView {
    var onDidMoveToSuperView: (() -> Void)?
    override func didMoveToSuperview() {
        onDidMoveToSuperView?()
    }
}
