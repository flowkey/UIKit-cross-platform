//
//  ButtonContentAlignmentTests.swift
//  UIKitTests
//
//  Created by Chris on 12.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
import UIKit

class ButtonContentAlignmentTests: XCTestCase {
    var button = Button(frame: .zero)
    let buttonSize = CGSize(width: 200, height: 100)
    let testImageSize = CGSize(width: 40, height: 40)

    override class func setUp() {
        super.setUp()
        #if os(iOS)
            loadCustomFont(name: "Roboto-Medium", fontExtension: "ttf")
        #endif
    }

    override func setUp() {
        button = Button(frame: .zero)
    }

    func testContentAlignmentSetsCorrectly() {
        button.contentHorizontalAlignment = .left
        button.contentVerticalAlignment = .top
        XCTAssertEqual(button.contentHorizontalAlignment, .left)
        XCTAssertEqual(button.contentVerticalAlignment, .top)

        button.contentHorizontalAlignment = .right
        button.contentVerticalAlignment = .bottom
        XCTAssertEqual(button.contentHorizontalAlignment, .right)
        XCTAssertEqual(button.contentVerticalAlignment, .bottom)

        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        XCTAssertEqual(button.contentHorizontalAlignment, .center)
        XCTAssertEqual(button.contentVerticalAlignment, .center)
    }

    func testDefaultContentAlignmentWithOnlyLabel() {
        button.setTitle(shortButtonText, for: .normal)
        button.titleLabel!.font = UIFont(name: "Roboto-Medium", size: smallFontSize)!
        button.frame = CGRect(origin: button.frame.origin, size: buttonSize)
        button.layoutSubviews()

        XCTAssertEqual(button.contentHorizontalAlignment, .center)
        XCTAssertEqual(button.contentVerticalAlignment, .center)
        XCTAssertEqualWithAccuracy(button.titleLabel!.frame.origin.x, buttonSize.width / 2 - button.titleLabel!.frame.width / 2, accuracy: 0.01)
        XCTAssertEqualWithAccuracy(button.titleLabel!.frame.origin.y, buttonSize.height / 2 - button.titleLabel!.frame.height / 2, accuracy: 0.18)
    }

    func testTopLeftContentAlignmentWithOnlyLabel() {
        button.setTitle(shortButtonText, for: .normal)
        button.titleLabel!.font = UIFont(name: "Roboto-Medium", size: smallFontSize)!
        button.frame = CGRect(origin: button.frame.origin, size: buttonSize)

        button.contentHorizontalAlignment = .left
        button.contentVerticalAlignment = .top
        button.layoutSubviews()

        XCTAssertEqual(button.titleLabel!.frame.origin.x, 0.0)
        XCTAssertEqual(button.titleLabel!.frame.origin.y, 0.0)
    }

    func testBottomRightContentAlignmentWithOnlyLabel() {
        button.setTitle(shortButtonText, for: .normal)
        button.titleLabel!.font = UIFont(name: "Roboto-Medium", size: smallFontSize)!
        button.frame = CGRect(origin: button.frame.origin, size: buttonSize)

        button.contentHorizontalAlignment = .right
        button.contentVerticalAlignment = .bottom
        button.layoutSubviews()

        XCTAssertEqual(button.titleLabel!.frame.origin.x, buttonSize.width - button.titleLabel!.frame.width)
        XCTAssertEqual(button.titleLabel!.frame.origin.y, buttonSize.height - button.titleLabel!.frame.height)
    }

    func testDefaultContentAlignmentWithOnlyImage() {
        button.setImage(.testImage(ofSize: testImageSize), for: .normal)
        button.frame = CGRect(origin: button.frame.origin, size: buttonSize)
        button.layoutSubviews()

        XCTAssertEqual(button.contentHorizontalAlignment, .center)
        XCTAssertEqual(button.contentVerticalAlignment, .center)
        XCTAssertEqual(button.imageView!.frame.origin.x, buttonSize.width / 2 - testImageSize.width / 2)
        XCTAssertEqual(button.imageView!.frame.origin.y, buttonSize.height / 2 - testImageSize.height / 2)
    }

    func testTopLeftContentAlignmentOnlyWithImage() {
        button.setImage(.testImage(ofSize: testImageSize), for: .normal)
        button.frame = CGRect(origin: button.frame.origin, size: buttonSize)
        button.layoutSubviews()

        button.contentHorizontalAlignment = .left
        button.contentVerticalAlignment = .top
        button.layoutSubviews()

        XCTAssertEqual(button.imageView!.frame.origin.x, 0.0)
        XCTAssertEqual(button.imageView!.frame.origin.y, 0.0)
    }

    func testBottomRightContentAlignmentOnlyWithImage() {
        button.setImage(.testImage(ofSize: testImageSize), for: .normal)
        button.frame = CGRect(origin: button.frame.origin, size: buttonSize)
        button.layoutSubviews()

        button.contentHorizontalAlignment = .right
        button.contentVerticalAlignment = .bottom
        button.layoutSubviews()

        XCTAssertEqual(button.imageView!.frame.origin.x, buttonSize.width  - testImageSize.width)
        XCTAssertEqual(button.imageView!.frame.origin.y, buttonSize.height - testImageSize.height)
    }
    

    func testContentAlignmentWithLabelAndImage() {
        button.setTitle(shortButtonText, for: .normal)
        button.titleLabel!.font = UIFont(name: "Roboto-Medium", size: smallFontSize)!
        button.setImage(.testImage(ofSize: testImageSize), for: .normal)
        button.frame = CGRect(origin: button.frame.origin, size: buttonSize)
        button.layoutSubviews()

        XCTAssertEqual(button.contentHorizontalAlignment, .center)
        XCTAssertEqual(button.contentVerticalAlignment, .center)
        XCTAssertEqualWithAccuracy(button.imageView!.frame.origin.x, (buttonSize.width - (testImageSize.width + button.titleLabel!.frame.width)) / 2, accuracy: 0.001)
        XCTAssertEqual(button.imageView!.frame.origin.y, buttonSize.height / 2 - testImageSize.height / 2)
        XCTAssertEqualWithAccuracy(button.titleLabel!.frame.origin.x, (buttonSize.width - button.titleLabel!.frame.width + testImageSize.width) / 2, accuracy: 0.001)
        XCTAssertEqualWithAccuracy(button.titleLabel!.frame.origin.y, (buttonSize.height - button.titleLabel!.frame.height) / 2, accuracy: 0.17)
    }

    func testTopLeftContentAlignmentWithLabelAndImage() {
        button.setTitle(shortButtonText, for: .normal)
        button.titleLabel!.font = UIFont(name: "Roboto-Medium", size: smallFontSize)!
        button.setImage(.testImage(ofSize: testImageSize), for: .normal)
        button.frame = CGRect(origin: button.frame.origin, size: buttonSize)
        button.layoutSubviews()

        button.contentHorizontalAlignment = .left
        button.contentVerticalAlignment = .top
        button.layoutSubviews()

        XCTAssertEqual(button.imageView!.frame.origin.x, 0.0)
        XCTAssertEqual(button.imageView!.frame.origin.y, 0.0)
        XCTAssertEqualWithAccuracy(button.titleLabel!.frame.origin.x, testImageSize.width, accuracy: 0.001)
        XCTAssertEqual(button.titleLabel!.frame.origin.y, 0.0)
    }

    func testBottomRightContentAlignmentWithLabelAndImage() {
        button.setTitle(shortButtonText, for: .normal)
        button.titleLabel!.font = UIFont(name: "Roboto-Medium", size: smallFontSize)!
        button.setImage(.testImage(ofSize: testImageSize), for: .normal)
        button.frame = CGRect(origin: button.frame.origin, size: buttonSize)
        button.layoutSubviews()

        button.contentHorizontalAlignment = .right
        button.contentVerticalAlignment = .bottom
        button.layoutSubviews()

        XCTAssertEqualWithAccuracy(button.imageView!.frame.origin.x, buttonSize.width - button.titleLabel!.frame.width - testImageSize.width, accuracy: 0.1)
        XCTAssertEqual(button.imageView!.frame.origin.y, buttonSize.height - testImageSize.height)
        XCTAssertEqual(button.titleLabel!.frame.origin.x, buttonSize.width - button.titleLabel!.frame.width)
        XCTAssertEqual(button.titleLabel!.frame.origin.y, buttonSize.height - button.titleLabel!.frame.height)
    }

}
