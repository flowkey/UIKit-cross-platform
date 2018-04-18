//
//  CAMediaTimingFunctionTests.swift
//  UIKitTests
//
//  Created by Michael Knoch on 23.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

class CAMediaTimingFunctionTests: XCTestCase {
    var view = UIView()

    override func setUp() {
        view = UIView()
        view.layer.hasBeenRenderedInThisPartOfOverallLayerHierarchy = true
    }

    func testCurveEasInWhenUsingUIViewAnimate() {
        UIView.animate(withDuration: 0, delay: 0, options: [.curveEaseIn], animations: {
            view.alpha = 0
        })

        if let timingFunction = view.layer.animations["opacity"]?.timingFunction {
            XCTAssertEqual(timingFunction[at: 0.2], 0.008, accuracy: 0.00001)
            XCTAssertEqual(timingFunction[at: 0.9], 0.729, accuracy: 0.00001)
        } else {
            XCTFail("timing function must not be nil")
        }
    }

    func testCurveEasOutWhenUsingUIViewAnimate() {
        UIView.animate(withDuration: 0, delay: 0, options: [.curveEaseOut], animations: {
            view.alpha = 0
        })

        if let timingFunction = view.layer.animations["opacity"]?.timingFunction {
            XCTAssertEqual(timingFunction[at: 0.2], 0.36, accuracy: 0.0001)
            XCTAssertEqual(timingFunction[at: 0.9], 0.99, accuracy: 0.0001)
        } else {
            XCTFail("timing function must not be nil")
        }
    }

    func testCurveEaseOutWhenUsingUIViewAnimateWithSpring() {
        UIView.animate(
            withDuration: 0,
            delay: 0,
            usingSpringWithDamping: 0,
            initialSpringVelocity: 0,
            options: [.curveEaseOut],
            animations: { view.alpha = 0 }
        )

        if let timingFunction = view.layer.animations["opacity"]?.timingFunction {
            XCTAssertEqual(timingFunction[at: 0.2], 0.36, accuracy: 0.0001)
            XCTAssertEqual(timingFunction[at: 0.9], 0.99, accuracy: 0.0001)
        } else {
            XCTFail("timing function must not be nil")
        }
    }
}
