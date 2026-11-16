//
//  ButtonLayoutingTests.swift
//  UIKit
//
//  Created by Chris on 15.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest

@MainActor
class ButtonLayoutingTests: XCTestCase {
    var button = Button(frame: .zero)

    override func setUp() {
        super.setUp()
        button = Button(frame: .zero)
    }
    
    func testLayoutSuperviewOnSizeToFit() {
        class ParentView: UIView {
            override func layoutSubviews() {
                super.layoutSubviews()
                for view in subviews { view.frame.size = CGSize(width: 300, height: 100) }
            }
        }
        let parentView = ParentView()
        parentView.addSubview(button)
        button.sizeToFit()
        parentView.layoutIfNeeded()

        XCTAssertEqual(button.frame.width, 300)
        XCTAssertEqual(button.frame.height, 100)
    }

    func testMultilineTitleWrapsAtButtonWidth() {
        button.setTitle("Back to wait mode", for: .normal)
        button.titleLabel!.font = UIFont(name: "roboto-medium", size: largeFontSize)!
        button.titleLabel!.numberOfLines = 0
        button.frame = CGRect(x: 0, y: 0, width: 150, height: 200)
        button.layoutIfNeeded()

        let singleLineHeight = button.titleLabel!.font.lineHeight
        XCTAssertLessThanOrEqual(button.titleLabel!.frame.width, 150)
        XCTAssertGreaterThan(button.titleLabel!.frame.height, singleLineHeight * 1.5)
    }
}
