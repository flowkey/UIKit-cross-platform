//
//  ButtonTests.swift
//  UIKitTests
//
//  Created by Chris on 04.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

class ButtonTests: XCTestCase {

    let shortButtonText = "Short"
    let mediumButtonText = "MediumButtonText"
    let longButtonText = "ThisIsALongTextToTestTheButton"

    let smallFontSize = 12.0
    let mediumFontSize = 15.0
    let largeFontSize = 18.0

    let smallImageSize = UIKit.CGSize(width: 40, height: 40)
    let mediumImageSize = UIKit.CGSize(width: 80, height: 80)
    let largeImageSize = UIKit.CGSize(width: 150, height: 150)

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

    func testFrameSizeToFitWithImage() {
        testButton.image = UIImage(texture: Texture(size: smallImageSize)!)
        testButton.sizeToFit()
        XCTAssertEqual(testButton.frame.size, smallImageSize)

        testButton.image = UIImage(texture: Texture(size: mediumImageSize)!)
        testButton.sizeToFit()
        XCTAssertEqual(testButton.frame.size, mediumImageSize)

        testButton.image = UIImage(texture: Texture(size: largeImageSize)!)
        testButton.sizeToFit()
        XCTAssertEqual(testButton.frame.size, largeImageSize)
    }
}

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
