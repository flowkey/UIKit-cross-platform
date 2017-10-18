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
        button.titleLabel!.font = UIFont(name: "roboto-medium", size: smallFontSize)!
        button.frame = CGRect(origin: button.frame.origin, size: buttonSize)
        button.layoutSubviews()

        XCTAssertEqual(button.contentHorizontalAlignment, .center)
        XCTAssertEqual(button.contentVerticalAlignment, .center)
        XCTAssertEqual(button.titleLabel!.frame.origin.x, buttonSize.width / 2 - button.titleLabel!.bounds.midX)
        XCTAssertEqual(button.titleLabel!.frame.origin.y.rounded(), (buttonSize.height / 2 - button.titleLabel!.bounds.midY).rounded())
    }

    func testTopLeftContentAlignmentWithOnlyLabel() {
        button.setTitle(shortButtonText, for: .normal)
        button.titleLabel!.font = UIFont(name: "roboto-medium", size: smallFontSize)!
        button.frame = CGRect(origin: button.frame.origin, size: buttonSize)

        button.contentHorizontalAlignment = .left
        button.contentVerticalAlignment = .top
        button.layoutSubviews()

        XCTAssertEqual(button.titleLabel!.frame.origin.x, 0.0)
        XCTAssertEqual(button.titleLabel!.frame.origin.y, 0.0)
    }

    func testTopLeftContentAlignmentAfterSizeToFitWithOnlyLabel() {
        button.setTitle(shortButtonText, for: .normal)
        button.titleLabel!.font = UIFont(name: "roboto-medium", size: smallFontSize)!
        button.sizeToFit()
        button.frame = CGRect(origin: button.frame.origin, size: buttonSize)

        button.contentHorizontalAlignment = .left
        button.contentVerticalAlignment = .top
        button.layoutSubviews()

        XCTAssertEqual(button.titleLabel!.frame.origin.x, 0.0)
        XCTAssertEqual(button.titleLabel!.frame.origin.y, defaultLabelVerticalPaddingAfterSizeToFit, accuracy: 0.0001)
    }

    func testBottomRightContentAlignmentWithOnlyLabel() {
        button.setTitle(shortButtonText, for: .normal)
        button.titleLabel!.font = UIFont(name: "roboto-medium", size: smallFontSize)!
        button.frame = CGRect(origin: button.frame.origin, size: buttonSize)

        button.contentHorizontalAlignment = .right
        button.contentVerticalAlignment = .bottom
        button.layoutSubviews()

        XCTAssertEqual(button.titleLabel!.frame.origin.x, buttonSize.width - button.titleLabel!.frame.width)
        XCTAssertEqual(button.titleLabel!.frame.origin.y, buttonSize.height - button.titleLabel!.frame.height)
    }

    func testBottomRightContentAlignmentAfterSizeToFitWithOnlyLabel() {
        button.setTitle(shortButtonText, for: .normal)
        button.titleLabel!.font = UIFont(name: "roboto-medium", size: smallFontSize)!
        button.sizeToFit()
        button.frame = CGRect(origin: button.frame.origin, size: buttonSize)

        button.contentHorizontalAlignment = .right
        button.contentVerticalAlignment = .bottom
        button.layoutSubviews()

        XCTAssertEqual(button.titleLabel!.frame.origin.x, buttonSize.width - button.titleLabel!.frame.width)
        XCTAssertEqual(button.titleLabel!.frame.origin.y, buttonSize.height - button.titleLabel!.frame.height - defaultLabelVerticalPaddingAfterSizeToFit)
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
        button.titleLabel!.font = UIFont(name: "roboto-medium", size: smallFontSize)!
        button.setImage(.testImage(ofSize: testImageSize), for: .normal)
        button.frame = CGRect(origin: button.frame.origin, size: buttonSize)
        button.layoutSubviews()

        XCTAssertEqual(button.contentHorizontalAlignment, .center)
        XCTAssertEqual(button.contentVerticalAlignment, .center)
        XCTAssertEqual(button.imageView!.frame.origin.x, (buttonSize.width - (testImageSize.width + button.titleLabel!.frame.width)) / 2, accuracy: 0.0001)
        XCTAssertEqual(button.imageView!.frame.origin.y, buttonSize.height / 2 - testImageSize.height / 2)
        XCTAssertEqual(button.titleLabel!.frame.origin.x, (buttonSize.width - button.titleLabel!.frame.width + testImageSize.width) / 2, accuracy: 0.0001)
        XCTAssertEqual(button.titleLabel!.frame.origin.y.rounded(), ((buttonSize.height - button.titleLabel!.frame.height) / 2).rounded())
    }

    func testTopLeftContentAlignmentWithLabelAndImage() {
        button.setTitle(shortButtonText, for: .normal)
        button.titleLabel!.font = UIFont(name: "roboto-medium", size: smallFontSize)!
        button.setImage(.testImage(ofSize: testImageSize), for: .normal)
        button.frame = CGRect(origin: button.frame.origin, size: buttonSize)
        button.layoutSubviews()

        button.contentHorizontalAlignment = .left
        button.contentVerticalAlignment = .top
        button.layoutSubviews()

        XCTAssertEqual(button.imageView!.frame.origin.x, 0.0)
        XCTAssertEqual(button.imageView!.frame.origin.y, 0.0)
        XCTAssertEqual(button.titleLabel!.frame.origin.x, testImageSize.width, accuracy: 0.0001)
        XCTAssertEqual(button.titleLabel!.frame.origin.y, 0.0)
    }

    func testBottomRightContentAlignmentWithLabelAndImage() {
        button.setTitle(shortButtonText, for: .normal)
        button.titleLabel!.font = UIFont(name: "roboto-medium", size: smallFontSize)!
        button.setImage(.testImage(ofSize: testImageSize), for: .normal)
        button.frame = CGRect(origin: button.frame.origin, size: buttonSize)
        button.layoutSubviews()

        button.contentHorizontalAlignment = .right
        button.contentVerticalAlignment = .bottom
        button.layoutSubviews()

        XCTAssertEqual(button.imageView!.frame.origin.x.rounded(), (buttonSize.width - button.titleLabel!.frame.width - testImageSize.width).rounded())
        XCTAssertEqual(button.imageView!.frame.origin.y, buttonSize.height - testImageSize.height)
        XCTAssertEqual(button.titleLabel!.frame.origin.x, buttonSize.width - button.titleLabel!.frame.width)
        XCTAssertEqual(button.titleLabel!.frame.origin.y, buttonSize.height - button.titleLabel!.frame.height)
    }
}
