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

class ButtonSizeToFitTests: XCTestCase {
    let testButton = Button(frame: .zero)

    override func setUp() {
        super.setUp()
        #if os(iOS)
            loadCustomFont(name: "Roboto-Medium", fontExtension: "ttf")
        #endif
    }
    
    override func tearDown() {

        super.tearDown()
    }

    func testSizeToFitWithNoLabelAndNoImage () {
        let defaultSizeForEmptyButton = CGSize(width: 30.0, height: 34.0)
        testButton.sizeToFit()
        XCTAssertEqual(testButton.frame.size, defaultSizeForEmptyButton)
    }

    func testSizeToFitWithSmallLabel() {
        testButton.setTitle(shortButtonText, for: .normal)
        testButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: smallFontSize)!
        testButton.layoutSubviews()
        testButton.sizeToFit()


        // move those to UIFontTests
        XCTAssertEqual(testButton.titleLabel?.font.lineHeight.rounded(), smallFontLineHeight)
        XCTAssertEqual(testButton.titleLabel?.font.fontName, "Roboto-Medium")

        let frameSizeWithShortLabelText = CGSize(width: 28.5, height: 26.5)
        XCTAssertEqualWithAccuracy(testButton.frame.width, frameSizeWithShortLabelText.width, accuracy: 1.5)
        XCTAssertEqualWithAccuracy(testButton.frame.height, frameSizeWithShortLabelText.height, accuracy: 0.5)
    }

    func testSizeToFitWithMediumLabel() {
        testButton.setTitle(mediumButtonText, for: .normal)
        testButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: mediumFontSize)!
        testButton.layoutSubviews()
        testButton.sizeToFit()

        let frameSizeWithMediumLabelText = CGSize(width: 136.5, height: 31.0)
        XCTAssertEqualWithAccuracy(testButton.frame.width, frameSizeWithMediumLabelText.width, accuracy: 0.5)
        XCTAssertEqualWithAccuracy(testButton.frame.height, frameSizeWithMediumLabelText.height, accuracy: 0.1)
        XCTAssertEqual(testButton.titleLabel?.font.lineHeight.rounded(), mediumFontLineHeight)
    }

    func testSizeToFitWithLargeLabel() {
        testButton.setTitle(longButtonText, for: .normal)
        testButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: largeFontSize)!
        testButton.layoutSubviews()
        testButton.sizeToFit()

        let frameSizeWithLongLabelText = CGSize(width: 307.5, height: 36.0)
        XCTAssertEqualWithAccuracy(testButton.frame.width, frameSizeWithLongLabelText.width, accuracy: 1.5)
        XCTAssertEqualWithAccuracy(testButton.frame.height, frameSizeWithLongLabelText.height, accuracy: 0.1)
        XCTAssertEqual(testButton.titleLabel?.font.lineHeight.rounded(), largeFontLineHeight)
    }

    func testSizeToFitWithMediumImage() {
        testButton.setImage(createTestImage(ofSize: mediumImageSize), for: .normal)
        testButton.layoutSubviews()
        testButton.sizeToFit()
        XCTAssertEqual(testButton.frame.size, mediumImageSize)
    }

}
