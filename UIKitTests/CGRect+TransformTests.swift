//
//  CGRect+TransformTests.swift
//  UIKit
//
//  Created by Geordie Jay on 12.02.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import XCTest

class CGRectTransformTests: XCTestCase {
    let accuracy: CGFloat = 1e-05
    let testFrame = CGRect(x: 50, y: 50, width: 100, height: 100)

    func testFrameApplyingScaleTransform() {
        let scaleFactor = CGFloat(2.0)
        let transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)

        let frame = testFrame.applying(transform)

        // If we imagine `origin` is a vector, it makes sense that it gets scaled too:
        XCTAssertEqual(frame.origin.x, testFrame.origin.x * scaleFactor)
        XCTAssertEqual(frame.origin.y, testFrame.origin.y * scaleFactor)
        XCTAssertEqual(frame.width, testFrame.width * scaleFactor)
        XCTAssertEqual(frame.height, testFrame.height * scaleFactor)
    }
}
