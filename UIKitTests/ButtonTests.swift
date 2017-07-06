//
//  ButtonTests.swift
//  UIKitTests
//
//  Created by Chris on 04.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest

#if os(iOS)
import UIKit
#else
@testable import UIKit
#endif

class ButtonTests: XCTestCase {

    let shortButtonText = "Short"
    let mediumButtonText = "MediumButtonText"
    let longButtonText = "ThisIsALongTextToTestTheButton"

    let smallFontSize: UIKit.CGFloat = 12.0
    let mediumFontSize: UIKit.CGFloat = 16.0 // default
    let largeFontSize: UIKit.CGFloat = 20.0

    let smallImageSize = UIKit.CGSize(width: 40, height: 40)
    let mediumImageSize = UIKit.CGSize(width: 80, height: 80)
    let largeImageSize = UIKit.CGSize(width: 150, height: 150)

    #if os(iOS)
    let testButton = UIButton(frame: .zero)
    #else
    let testButton = Button(frame: .zero)
    #endif

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        testButton.setTitle(nil, for: .normal)
        //        testButton.setImage(nil, for: .normal)
        super.tearDown()
    }

    func testSetTitle() {
        testButton.setTitle(shortButtonText, for: .normal)
        XCTAssertEqual(testButton.titleLabel?.text, shortButtonText)
        testButton.setTitle(mediumButtonText, for: .normal)
        XCTAssertEqual(testButton.titleLabel?.text, mediumButtonText)
        testButton.setTitle(longButtonText, for: .normal)
        XCTAssertEqual(testButton.titleLabel?.text, longButtonText)
    }

    func testFrameSizeToFitWithLabel() {
        testButton.setTitle(shortButtonText, for: .normal)
        testButton.titleLabel?.font = .systemFont(ofSize: smallFontSize)
        testButton.sizeToFit()
        let frameSizeWithShortLabelText = UIKit.CGSize(width: 28.5, height: 14.5)
        XCTAssertEqual(testButton.frame.size, frameSizeWithShortLabelText)

        testButton.setTitle(mediumButtonText, for: .normal)
        testButton.titleLabel?.font = .systemFont(ofSize: mediumFontSize)
        testButton.sizeToFit()
        let frameSizeWithMediumLabelText = UIKit.CGSize(width: 136.5, height: 19.0)
        XCTAssertEqual(testButton.frame.size, frameSizeWithMediumLabelText)

        testButton.setTitle(longButtonText, for: .normal)
        testButton.titleLabel?.font = .systemFont(ofSize: largeFontSize)
        testButton.sizeToFit()
        let frameSizeWithLongLabelText = UIKit.CGSize(width: 306.5, height: 24.0)
        XCTAssertEqual(testButton.frame.size, frameSizeWithLongLabelText)
    }

        func testFrameSizeToFitWithImage() {
            #if os(iOS)
            UIGraphicsBeginImageContext(mediumImageSize)
            testButton.setImage(UIGraphicsGetImageFromCurrentImageContext(), for: .normal)
            UIGraphicsEndImageContext()
            #else
            testButton.image = UIImage(texture: Texture(size: mediumImageSize)!)
            #endif

            testButton.sizeToFit()
            XCTAssertEqual(testButton.frame.size, mediumImageSize)
        }

        func testContentEdgeInsets() {
            testButton.setTitle(mediumButtonText, for: .normal)
            #if os(iOS)
            UIGraphicsBeginImageContext(smallImageSize)
            testButton.setImage(UIGraphicsGetImageFromCurrentImageContext(), for: .normal)
            UIGraphicsEndImageContext()
            #else
            testButton.image = UIImage(texture: Texture(size: smallImageSize)!)
            #endif
            testButton.sizeToFit()

            XCTAssertEqual(testButton.titleLabel?.frame.origin, CGPoint(x: 40.0, y: 0.0))
            XCTAssertEqual(testButton.imageView?.frame.origin, CGPoint(x: 0.0, y: 0.0))

            testButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 0, right: 0)

            XCTAssertEqual(testButton.titleLabel?.frame.origin, CGPoint(x: 50.0, y: 10.0))
            XCTAssertEqual(testButton.imageView?.frame.origin, CGPoint(x: 10.0, y: 10.0))

            testButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)

            // TODO: correct tests, should not be equal to previous frame.origin
            XCTAssertEqual(testButton.titleLabel?.frame.origin, CGPoint(x: 40.0, y: 0.0))
            XCTAssertEqual(testButton.imageView?.frame.origin, CGPoint(x: 0.0, y: 0.0))
        }
}

#if !os(iOS)
    extension Texture {
        convenience init?(size: UIKit.CGSize) {
            var gpuImage = GPU_Image()

            gpuImage.w = UInt16(size.width)
            gpuImage.h = UInt16(size.height)

            // TODO: check capacity of 16 or initialize in different way without explizit capacity
            let gpuImagePointer = UnsafeMutablePointer<GPU_Image>.allocate(capacity: 16)
            gpuImagePointer.initialize(to: gpuImage)

            self.init(gpuImage: gpuImagePointer)
        }
    }
#endif
