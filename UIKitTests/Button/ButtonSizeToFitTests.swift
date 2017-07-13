//
//  ButtonSizeToFitTests.swift
//  UIKitTests
//
//  Created by Chris on 12.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
import UIKit

class ButtonSizeToFitTests: XCTestCase {
    var button = Button(frame: .zero)

    override class func setUp() {
        super.setUp()
        #if os(iOS)
            loadCustomFont(name: "roboto-medium", fontExtension: "ttf")
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
        button.layoutSubviews()
        button.sizeToFit()


        // move those to UIFontTests
        XCTAssertEqual(button.titleLabel!.font.lineHeight.rounded(), smallFontLineHeight)
        XCTAssertEqual(button.titleLabel!.font.fontName, "roboto-medium")

        let frameSizeWithShortLabelText = CGSize(width: 28.5, height: 26.5)
        XCTAssertEqualWithAccuracy(button.frame.width, frameSizeWithShortLabelText.width, accuracy: 1.5)
        XCTAssertEqualWithAccuracy(button.frame.height, frameSizeWithShortLabelText.height, accuracy: 0.5)
    }

    func testSizeToFitWithMediumLabel() {
        button.setTitle(mediumButtonText, for: .normal)
        button.titleLabel!.font = UIFont(name: "roboto-medium", size: mediumFontSize)!
        button.layoutSubviews()
        button.sizeToFit()

        let frameSizeWithMediumLabelText = CGSize(width: 136.5, height: 31.0)
        XCTAssertEqualWithAccuracy(button.frame.width, frameSizeWithMediumLabelText.width, accuracy: 0.5)
        XCTAssertEqualWithAccuracy(button.frame.height, frameSizeWithMediumLabelText.height, accuracy: 0.1)
        XCTAssertEqual(button.titleLabel!.font.lineHeight.rounded(), mediumFontLineHeight)
    }

    func testSizeToFitWithLargeLabel() {
        button.setTitle(longButtonText, for: .normal)
        button.titleLabel!.font = UIFont(name: "roboto-medium", size: largeFontSize)!
        button.layoutSubviews()
        button.sizeToFit()

        let frameSizeWithLongLabelText = CGSize(width: 307.5, height: 36.0)
        XCTAssertEqualWithAccuracy(button.frame.width, frameSizeWithLongLabelText.width, accuracy: 1.5)
        XCTAssertEqualWithAccuracy(button.frame.height, frameSizeWithLongLabelText.height, accuracy: 0.1)
        XCTAssertEqual(button.titleLabel!.font.lineHeight.rounded(), largeFontLineHeight)
    }

    func testSizeToFitWithMediumImage() {
        button.setImage(.testImage(ofSize: mediumImageSize), for: .normal)
        button.layoutSubviews()
        button.sizeToFit()
        XCTAssertEqual(button.frame.size, mediumImageSize)
    }

}
