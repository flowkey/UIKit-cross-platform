//
//  CAMediaTimingFunctionTests.swift
//  UIKitTests
//
//  Created by Michael Knoch on 23.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit
typealias CAMediaTimingFunction = UIKit.CAMediaTimingFunction

class CAMediaTimingFunctionTests: XCTestCase {

    func testCurveEasIn() {
        let layer = CALayer()
        UIView.animate(withDuration: 5, delay: 0, options: [.curveEaseIn], animations: {
            layer.opacity = 0
        })

        if let timingFunction = layer.animations.first?.animation.timingFunction {
            XCTAssertEqual(timingFunction.compute(x: 0.2), 0.008, accuracy: 0.00001)
            XCTAssertEqual(timingFunction.compute(x: 0.9), 0.729, accuracy: 0.00001)
        } else {
            XCTFail("timing function must not be nil")
        }
    }

    func testCurveEaseOut() {
        let layer = CALayer()
        UIView.animate(withDuration: 5, delay: 0, options: [.curveEaseOut], animations: {
            layer.opacity = 0
        })

        if let timingFunction = layer.animations.first?.animation.timingFunction {
            XCTAssertEqual(timingFunction.compute(x: 0.2), 0.36, accuracy: 0.0001)
            XCTAssertEqual(timingFunction.compute(x: 0.9), 0.99, accuracy: 0.0001)
        } else {
            XCTFail("timing function must not be nil")
        }
    }
}
