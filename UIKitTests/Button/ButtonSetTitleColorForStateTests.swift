//
//  ButtonSetTitleColorForStateTests.swift
//  UIKitTests
//
//  Created by Chris on 31.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
import UIKit

class ButtonSetTitleColorForStateTests: XCTestCase {

    var button = Button(frame: .zero)

    override func setUp() {
        super.setUp()
        button = Button(frame: .zero)
    }

    func testNoTitleColorWithoutTitleForNormalState() {
        button.setTitleColor(.blue, for: .normal)
        button.layoutSubviews()

        XCTAssertFalse(button.titleLabel!.textColor == UIColor.blue)
    }

    func testExistingTitleColorWithTitleForNormalState() {
        button.setTitleColor(.blue, for: .normal)
        button.setTitle(shortButtonText, for: .normal)
        button.layoutSubviews()

        XCTAssertTrue(button.titleLabel!.textColor == UIColor.blue)
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

        XCTAssertTrue(button.titleLabel!.shadowColor! == UIColor.white)
    }

    func testSetTitleColorForSelectedState() {
        button.setTitleColor(.red, for: .selected)
        button.setTitle(shortButtonText, for: .selected)
        button.isSelected = true
        button.layoutSubviews()

        XCTAssertTrue(button.titleLabel!.textColor == UIColor.red)
    }

    func testSetTitleColorNormalStateFallback() {
        button.setTitleColor(.green, for: .normal)
        button.setTitle(shortButtonText, for: .normal)
        button.isSelected = true
        button.layoutSubviews()

        XCTAssertTrue(button.titleLabel!.textColor == UIColor.green)
    }
}

