//
//  CALayerTests.swift
//  UIKitTests
//
//  Created by Geordie Jay on 01.02.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import XCTest
import UIKit

class CALayerTests: XCTestCase {
    let accuracy: CGFloat = 1e-05
    let testFrame = CGRect(x: 50, y: 50, width: 100, height: 100)

    // `frame` is a computed property, so setting it and then getting it again should produce the same value!
    func testLayerFrameGetterAndSetter() {
        let layer = CALayer()
        layer.frame = testFrame
        XCTAssertEqual(layer.frame, testFrame)
    }

    func testLayerFrameWithDifferentAnchorPoint() {
        let layer = CALayer()
        layer.anchorPoint = CGPoint(x: 0.1, y: 0.1)
        layer.frame = testFrame
        XCTAssertEqual(layer.frame, testFrame)
    }

    func testLayerFrameWithTransform() {
        let layer = CALayer()
        // two different scale values to detect logic errors e.g. x/y swapped accidentally:
        layer.setAffineTransform(CGAffineTransform(scaleX: 0.25, y: 0.75))
        layer.frame = testFrame

        XCTAssertEqual(layer.frame.origin.x, testFrame.origin.x, accuracy: accuracy)
        XCTAssertEqual(layer.frame.origin.y, testFrame.origin.y, accuracy: accuracy)
        XCTAssertEqual(layer.frame.width, testFrame.width, accuracy: accuracy)
        XCTAssertEqual(layer.frame.height, testFrame.height, accuracy: accuracy)
    }

    func testLayerBoundsSizeWithTransform() {
        let layer = CALayer()
        let scaleFactor: CGFloat = 0.5
        layer.setAffineTransform(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
        layer.frame = testFrame

        XCTAssertEqual(layer.bounds.width, testFrame.width / scaleFactor, accuracy: accuracy)
        XCTAssertEqual(layer.bounds.height, testFrame.height / scaleFactor, accuracy: accuracy)
    }

    func testBoundsSizeMovesAroundAnchorPoint() {
        let layer = CALayer()

        layer.frame = testFrame
        layer.bounds.size = CGSize(width: 1000, height: 1000)

        // Bounds size expands from layer.anchorPoint which is per default in the middle of the frame.
        // This means that increasing bounds.size by 900 in each dimension effectively moves frame.origin
        // up and left by 450 in each dimension:
        XCTAssertEqual(layer.frame.origin.x, -400.0, accuracy: accuracy)
        XCTAssertEqual(layer.frame.origin.y, -400.0, accuracy: accuracy)
    }
}
