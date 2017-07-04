//
//  ButtonTests.swift
//  UIKitTests
//
//  Created by Chris on 04.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
import UIKit

class ButtonTests: XCTestCase {

    let shortButtonText = "Short"
    let mediumButtonText = "MediumButtonText"
    let longButtonText = "ThisIsALongTextToTestTheButton"

    let smallFontSize = 12.0
    let mediumFontSize = 15.0
    let largeFontSize = 18.0

    let testButton = Button(frame: .zero)

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        testButton.titleLabel = nil
        testButton.image = nil
        super.tearDown()
    }

    func testSetText() {
        testButton.text = shortButtonText
        XCTAssertEqual(testButton.titleLabel?.text, shortButtonText)
        testButton.text = mediumButtonText
        XCTAssertEqual(testButton.titleLabel?.text, mediumButtonText)
        testButton.text = longButtonText
        XCTAssertEqual(testButton.titleLabel?.text, longButtonText)
    }

    func testSetTitle() {
        testButton.setTitle(shortButtonText)
        XCTAssertEqual(testButton.titleLabel?.text, shortButtonText)
        testButton.setTitle(mediumButtonText)
        XCTAssertEqual(testButton.titleLabel?.text, mediumButtonText)
        testButton.setTitle(longButtonText)
        XCTAssertEqual(testButton.titleLabel?.text, longButtonText)
    }


    func testFrameSizeToFitWithLabel() {
        testButton.text = shortButtonText
        testButton.sizeToFit()
        let frameSizeWithShortLabelText = UIKit.CGSize(width: 38.0, height: 19.0)
        XCTAssertEqual(testButton.frame.size, frameSizeWithShortLabelText)

        testButton.text = mediumButtonText
        testButton.sizeToFit()
        let frameSizeWithMediumLabelText = UIKit.CGSize(width: 136.5, height: 19.0)
        XCTAssertEqual(testButton.frame.size, frameSizeWithMediumLabelText)
        
        testButton.text = longButtonText
        testButton.sizeToFit()
        let frameSizeWithLongLabelText = UIKit.CGSize(width: 245.0, height: 19.0)
        XCTAssertEqual(testButton.frame.size, frameSizeWithLongLabelText)
    }
}
