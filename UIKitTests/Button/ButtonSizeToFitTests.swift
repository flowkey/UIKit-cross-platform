//
//  ButtonSizeToFitTests.swift
//  UIKitTests
//
//  Created by Chris on 12.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
#if os(iOS)
    import UIKit
#else
    @testable import UIKit
#endif

private let frameSizeWithShortLabelText = CGSize(width: 28.5, height: 26.5)
private let frameSizeWithMediumLabelText = CGSize(width: 137, height: 31.0)
private let frameSizeWithLongLabelText = CGSize(width: 307.5, height: 36.0)

class ButtonSizeToFitTests: XCTestCase {
    var button = Button(frame: .zero)

    override class func setUp() {
        super.setUp()
        #if os(iOS)
            loadCustomFont(name: "roboto-medium", fontExtension: "ttf")
        #else
            UIFont.loadSystemFonts()
        #endif
    }

    override func setUp() {
        button = Button(frame: .zero)
    }

    func testSizeToFitWithNoLabelAndNoImage () {
        let defaultSizeForEmptyButton = CGSize(width: 30.0, height: 34.0)
        button.sizeToFit()
        XCTAssertEqual(button.frame.size, defaultSizeForEmptyButton)
    }

    func testSizeToFitWithSmallLabel() {
        button.setTitle(shortButtonText, for: .normal)
        button.titleLabel!.font = UIFont(name: "roboto-medium", size: smallFontSize)!
        button.sizeToFit()

        XCTAssertEqualWithAccuracy(button.frame.width, frameSizeWithShortLabelText.width, accuracy: 1.5)
        XCTAssertEqualWithAccuracy(button.frame.height, frameSizeWithShortLabelText.height, accuracy: 0.5)
    }

    func testSizeToFitWithMediumLabel() {
        button.setTitle(mediumButtonText, for: .normal)
        button.titleLabel!.font = UIFont(name: "roboto-medium", size: mediumFontSize)!
        button.sizeToFit()

        XCTAssertEqualWithAccuracy(button.frame.width, frameSizeWithMediumLabelText.width, accuracy: 1.5)
        XCTAssertEqualWithAccuracy(button.frame.height, frameSizeWithMediumLabelText.height, accuracy: 0.1)
    }

    func testSizeToFitWithLargeLabel() {
        button.setTitle(longButtonText, for: .normal)
        button.titleLabel!.font = UIFont(name: "roboto-medium", size: largeFontSize)!
        button.sizeToFit()

        XCTAssertEqualWithAccuracy(button.frame.width, frameSizeWithLongLabelText.width, accuracy: 1.5)
        XCTAssertEqualWithAccuracy(button.frame.height, frameSizeWithLongLabelText.height, accuracy: 0.1)
    }

    func testSizeToFitWithMediumImage() {
        button.setImage(.testImage(ofSize: mediumImageSize), for: .normal)
        button.sizeToFit()
        XCTAssertEqual(button.frame.size, mediumImageSize)
    }

    func testSizeToFitWithLabelAndImage() {
        button.setImage(.testImage(ofSize: mediumImageSize), for: .normal)
        button.setTitle(mediumButtonText, for: .normal)
        button.titleLabel!.font = UIFont(name: "roboto-medium", size: mediumFontSize)!
        button.sizeToFit()

        XCTAssertEqualWithAccuracy(button.frame.width, (mediumImageSize.width + frameSizeWithMediumLabelText.width), accuracy: 1.0)
        XCTAssertEqualWithAccuracy(button.frame.height, max(mediumImageSize.height, frameSizeWithMediumLabelText.height), accuracy: 0.0001)
    }
}
