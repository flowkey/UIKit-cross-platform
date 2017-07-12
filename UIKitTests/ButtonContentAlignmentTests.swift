//
//  ButtonContentAlignmentTests.swift
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

class ButtonContentAlignmentTests: XCTestCase {
    let testButton = Button(frame: .zero)
    let buttonFrameSize = UIKit.CGSize(width: 200, height: 100)
    let testImageSize = UIKit.CGSize(width: 40, height: 40)

    override func setUp() {
        super.setUp()
        #if os(iOS)
            loadCustomFont(name: "Roboto-Medium", fontExtension: "ttf")
        #endif
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDefaultContentAlignmentWithOnlyLabel() {
        testButton.setTitle(shortButtonText, for: .normal)
        testButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: smallFontSize)!
        testButton.sizeToFit()
        testButton.frame = CGRect(origin: testButton.frame.origin, size: buttonFrameSize)
        testButton.layoutSubviews()

        XCTAssertEqual(testButton.contentHorizontalAlignment, UIControlContentHorizontalAlignment.center)
        XCTAssertEqual(testButton.contentVerticalAlignment, UIControlContentVerticalAlignment.center)
        XCTAssertEqualWithAccuracy((testButton.titleLabel?.frame.origin.x)!, buttonFrameSize.width / 2 - (testButton.titleLabel?.frame.width)! / 2, accuracy: 0.01)
        XCTAssertEqualWithAccuracy((testButton.titleLabel?.frame.origin.y)!, buttonFrameSize.height / 2 - (testButton.titleLabel?.frame.height)! / 2, accuracy: 0.18)
    }

    func testTopLeftContentAlignmentWithOnlyLabel() {
        testButton.setTitle(shortButtonText, for: .normal)
        testButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: smallFontSize)!
        testButton.sizeToFit()
        testButton.frame = CGRect(origin: testButton.frame.origin, size: buttonFrameSize)
        testButton.layoutSubviews()

        testButton.contentHorizontalAlignment = .left
        testButton.contentVerticalAlignment = .top
        testButton.layoutSubviews()
        XCTAssertEqual(testButton.contentHorizontalAlignment, UIControlContentHorizontalAlignment.left)
        XCTAssertEqual(testButton.contentVerticalAlignment, UIControlContentVerticalAlignment.top)
        XCTAssertEqual(testButton.titleLabel?.frame.origin.x, 0.0)
        XCTAssertEqualWithAccuracy((testButton.titleLabel?.frame.origin.y)!, defaultLabelVerticalPadding, accuracy: 0.001)
    }

    func testBottomRightContentAlignmentWithOnlyLabel() {
        testButton.setTitle(shortButtonText, for: .normal)
        testButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: smallFontSize)!
        testButton.sizeToFit()
        testButton.frame = CGRect(origin: testButton.frame.origin, size: buttonFrameSize)
        testButton.layoutSubviews()

        testButton.contentHorizontalAlignment = .right
        testButton.contentVerticalAlignment = .bottom
        testButton.layoutSubviews()
        XCTAssertEqual(testButton.contentHorizontalAlignment, UIControlContentHorizontalAlignment.right)
        XCTAssertEqual(testButton.contentVerticalAlignment, UIControlContentVerticalAlignment.bottom)
        XCTAssertEqual(testButton.titleLabel?.frame.origin.x, buttonFrameSize.width - (testButton.titleLabel?.frame.width)!)
        XCTAssertEqual(testButton.titleLabel?.frame.origin.y, buttonFrameSize.height - (testButton.titleLabel?.frame.height)! - defaultLabelVerticalPadding)
    }

    func testContentAlignmentWithOnlyImage() {
        testButton.setImage(createTestImage(ofSize: testImageSize), for: .normal)
        testButton.sizeToFit()
        testButton.frame = CGRect(origin: testButton.frame.origin, size: buttonFrameSize)
        testButton.layoutSubviews()

        XCTAssertEqual(testButton.contentHorizontalAlignment, UIControlContentHorizontalAlignment.center)
        XCTAssertEqual(testButton.contentVerticalAlignment, UIControlContentVerticalAlignment.center)
        XCTAssertEqual(testButton.imageView?.frame.origin.x, buttonFrameSize.width / 2 - testImageSize.width / 2)
        XCTAssertEqual(testButton.imageView?.frame.origin.y, buttonFrameSize.height / 2 - testImageSize.height / 2)

        testButton.contentHorizontalAlignment = .left
        testButton.contentVerticalAlignment = .top
        testButton.layoutSubviews()

        XCTAssertEqual(testButton.contentHorizontalAlignment, UIControlContentHorizontalAlignment.left)
        XCTAssertEqual(testButton.contentVerticalAlignment, UIControlContentVerticalAlignment.top)
        XCTAssertEqual(testButton.imageView?.frame.origin.x, 0.0)
        XCTAssertEqual(testButton.imageView?.frame.origin.y, 0.0)

        testButton.contentHorizontalAlignment = .right
        testButton.contentVerticalAlignment = .bottom
        testButton.layoutSubviews()

        XCTAssertEqual(testButton.contentHorizontalAlignment, UIControlContentHorizontalAlignment.right)
        XCTAssertEqual(testButton.contentVerticalAlignment, UIControlContentVerticalAlignment.bottom)
        XCTAssertEqual(testButton.imageView?.frame.origin.x, buttonFrameSize.width  - testImageSize.width)
        XCTAssertEqual(testButton.imageView?.frame.origin.y, buttonFrameSize.height - testImageSize.height)
    }

    func testContentAlignmentWithLabelAndImage() {
        testButton.setTitle(shortButtonText, for: .normal)
        testButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: smallFontSize)!

        testButton.setImage(createTestImage(ofSize: testImageSize), for: .normal)

        testButton.sizeToFit()
        testButton.frame = CGRect(origin: testButton.frame.origin, size: buttonFrameSize)
        testButton.layoutSubviews()

        XCTAssertEqual(testButton.contentHorizontalAlignment, UIControlContentHorizontalAlignment.center)
        XCTAssertEqual(testButton.contentVerticalAlignment, UIControlContentVerticalAlignment.center)
        XCTAssertEqualWithAccuracy((testButton.imageView?.frame.origin.x)!, (buttonFrameSize.width - (testImageSize.width + (testButton.titleLabel?.frame.width)!)) / 2, accuracy: 0.001)
        XCTAssertEqual(testButton.imageView?.frame.origin.y, buttonFrameSize.height / 2 - testImageSize.height / 2)
        XCTAssertEqualWithAccuracy((testButton.titleLabel?.frame.origin.x)!, (buttonFrameSize.width - (testButton.titleLabel?.frame.width)! + testImageSize.width) / 2, accuracy: 0.001)
        XCTAssertEqualWithAccuracy((testButton.titleLabel?.frame.origin.y)!, (buttonFrameSize.height - (testButton.titleLabel?.frame.height)!) / 2, accuracy: 0.17)

        testButton.contentHorizontalAlignment = .left
        testButton.contentVerticalAlignment = .top
        testButton.layoutSubviews()
        XCTAssertEqual(testButton.contentHorizontalAlignment, UIControlContentHorizontalAlignment.left)
        XCTAssertEqual(testButton.contentVerticalAlignment, UIControlContentVerticalAlignment.top)
        XCTAssertEqual(testButton.imageView?.frame.origin.x, 0.0)
        XCTAssertEqual(testButton.imageView?.frame.origin.y, 0.0)
        XCTAssertEqualWithAccuracy((testButton.titleLabel?.frame.origin.x)!, testImageSize.width, accuracy: 0.001)
        XCTAssertEqual((testButton.titleLabel?.frame.origin.y)!, 0.0)

        testButton.contentHorizontalAlignment = .right
        testButton.contentVerticalAlignment = .bottom
        testButton.layoutSubviews()
        XCTAssertEqual(testButton.contentHorizontalAlignment, UIControlContentHorizontalAlignment.right)
        XCTAssertEqual(testButton.contentVerticalAlignment, UIControlContentVerticalAlignment.bottom)
        XCTAssertEqualWithAccuracy((testButton.imageView?.frame.origin.x)!, buttonFrameSize.width - (testButton.titleLabel?.frame.width)! - testImageSize.width, accuracy: 0.1)
        XCTAssertEqual(testButton.imageView?.frame.origin.y, buttonFrameSize.height - testImageSize.height)
        XCTAssertEqual(testButton.titleLabel?.frame.origin.x, buttonFrameSize.width - (testButton.titleLabel?.frame.width)!)
        XCTAssertEqual(testButton.titleLabel?.frame.origin.y, buttonFrameSize.height - (testButton.titleLabel?.frame.height)!)
    }

}
