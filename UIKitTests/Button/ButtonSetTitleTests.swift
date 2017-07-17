//
//  ButtonSetTitleTests.swift
//  UIKit
//
//  Created by Chris on 13.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
import UIKit

class ButtonSetTitleTests: XCTestCase {
    
    var button = Button(frame: .zero)

    override func setUp() {
        super.setUp()
        button = Button(frame: .zero)
    }

    func testSetTitle() {
        button.setTitle(shortButtonText, for: .normal)
        button.layoutSubviews()
        XCTAssertEqual(button.titleLabel?.text, shortButtonText)

        button.setTitle(mediumButtonText, for: .normal)
        button.layoutSubviews()
        XCTAssertEqual(button.titleLabel?.text, mediumButtonText)

        button.setTitle(longButtonText, for: .normal)
        button.layoutSubviews()
        XCTAssertEqual(button.titleLabel?.text, longButtonText)
    }

    func testSetAttributedTitle() {
        let simpleAttributedText = NSAttributedString(string: "attributed Text")
        button.setAttributedTitle(simpleAttributedText, for: .normal)
        button.layoutSubviews()
        XCTAssertEqual(button.titleLabel?.attributedText, simpleAttributedText)
        XCTAssertEqual(button.titleLabel?.text, simpleAttributedText.string)
    }
}
