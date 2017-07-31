//
//  ButtonSetTitleForStateTests.swift
//  UIKit
//
//  Created by Chris on 13.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
import UIKit

class ButtonSetTitleForStateTests: XCTestCase {
    
    var button = Button(frame: .zero)

    override func setUp() {
        super.setUp()
        button = Button(frame: .zero)
    }

    func testSetTitleForNormalState() {
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

    func testSetAttributedTitleForNormalState() {
        let simpleAttributedText = NSAttributedString(string: "attributed Text")
        button.setAttributedTitle(simpleAttributedText, for: .normal)
        button.layoutSubviews()
        XCTAssertEqual(button.titleLabel?.text, simpleAttributedText.string)
    }

    func testSetTitleForSelectedState() {
        button.setTitle(mediumButtonText, for: .selected)
        button.isSelected = true
        button.layoutSubviews()
        XCTAssertEqual(button.titleLabel?.text, mediumButtonText)
    }

    func testSetAttributedTitleForSelectedState() {
        let simpleAttributedText = NSAttributedString(string: "attributed Text")
        button.setAttributedTitle(simpleAttributedText, for: .selected)
        button.isSelected = true
        button.layoutSubviews()
        XCTAssertEqual(button.titleLabel?.text, simpleAttributedText.string)

    }

    func testSetTitleForHighlightedState() {
        button.setTitle(mediumButtonText, for: .highlighted)
        button.isHighlighted = true
        button.layoutSubviews()
        XCTAssertEqual(button.titleLabel?.text, mediumButtonText)
    }

    func testSetAttributedTitleForHighlightedState() {
        let simpleAttributedText = NSAttributedString(string: "attributed Text")
        button.setAttributedTitle(simpleAttributedText, for: .highlighted)
        button.isHighlighted = true
        button.layoutSubviews()
        XCTAssertEqual(button.titleLabel?.text, simpleAttributedText.string)
    }

    func testTitleForNormalStateFallbackWhenSelected() {
        button.setTitle(mediumButtonText, for: .normal)
        button.isSelected = true
        button.layoutSubviews()
        XCTAssertEqual(button.titleLabel?.text, mediumButtonText)
    }

    func testAttributedTitleForNormalStateFallbackWhenHighlighted() {
        let simpleAttributedText = NSAttributedString(string: "attributed Text")
        button.setAttributedTitle(simpleAttributedText, for: .normal)
        button.isHighlighted = true
        button.layoutSubviews()
        XCTAssertEqual(button.titleLabel?.text, simpleAttributedText.string)
    }
}
