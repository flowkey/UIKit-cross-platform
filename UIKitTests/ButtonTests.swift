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
    let mediumFontSize = 16.0 // default
    let largeFontSize = 20.0

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
        testButton.titleLabel?.font = .systemFont(ofSize: smallFontSize)
        testButton.sizeToFit()
        let frameSizeWithShortLabelText = UIKit.CGSize(width: 28.5, height: 14.5)
        XCTAssertEqual(testButton.frame.size, frameSizeWithShortLabelText)

        testButton.text = mediumButtonText
        testButton.titleLabel?.font = .systemFont(ofSize: mediumFontSize)
        testButton.sizeToFit()
        let frameSizeWithMediumLabelText = UIKit.CGSize(width: 136.5, height: 19.0)
        XCTAssertEqual(testButton.frame.size, frameSizeWithMediumLabelText)
        
        testButton.text = longButtonText
        testButton.titleLabel?.font = .systemFont(ofSize: largeFontSize)
        testButton.sizeToFit()
        let frameSizeWithLongLabelText = UIKit.CGSize(width: 306.5, height: 24.0)
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

    func testContentEdgeInsets() {
        testButton.text = mediumButtonText
        testButton.image = UIImage(texture: Texture(size: smallImageSize)!)
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
