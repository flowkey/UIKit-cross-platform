//
//  ButtonSetTitleColorForStateTests.swift
//  UIKitTests
//
//  Created by Chris on 31.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest

class ButtonSetTitleColorForStateTests: XCTestCase {

    var button = Button(frame: .zero)

    override func setUp() {
        super.setUp()
        button = Button(frame: .zero)
    }

    func testNoTitleColorWithoutTitleForNormalState() {
        button.setTitleColor(.blue, for: .normal)
        button.layoutSubviews()

        XCTAssertNotEqual(button.titleLabel?.textColor, .blue)
    }

    func testExistingTitleColorWithTitleForNormalState() {
        button.setTitleColor(.blue, for: .normal)
        button.setTitle(shortButtonText, for: .normal)
        button.layoutSubviews()

        XCTAssertEqual(button.titleLabel!.textColor, .blue)
    }

    func testNoTitleShadowColorWithoutTitleForNormalState() {
        button.setTitleShadowColor(.white, for: .normal)
        button.layoutSubviews()

        XCTAssertNil(button.titleLabel!.shadowColor)
    }

    func testExistingTitleShadowColorWithTitleForNormalState() {
        button.setTitleShadowColor(.white, for: .normal)
        button.setTitle(shortButtonText, for: .normal)
        button.layoutSubviews()

        XCTAssertEqual(button.titleLabel?.shadowColor, .white)
    }

    func testSetTitleColorForSelectedState() {
        button.setTitleColor(.red, for: .selected)
        button.setTitle(shortButtonText, for: .selected)
        button.isSelected = true
        button.layoutSubviews()

        XCTAssertEqual(button.titleLabel?.textColor, .red)
    }

    func testSetTitleColorNormalStateFallback() {
        button.setTitleColor(.green, for: .normal)
        button.setTitle(shortButtonText, for: .normal)
        button.isSelected = true
        button.layoutSubviews()

        XCTAssertEqual(button.titleLabel?.textColor, .green)
    }
}

