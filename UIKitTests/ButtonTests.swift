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

    let smallFontSize: UIKit.CGFloat = 12
    let smallFontLineHeight: UIKit.CGFloat = 14
    let mediumFontSize: UIKit.CGFloat = 16 // default
    let mediumFontLineHeight: UIKit.CGFloat = 19
    let largeFontSize: UIKit.CGFloat = 20
    let largeFontLineHeight: UIKit.CGFloat = 23

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
        testButton.setTitle("", for: .normal)
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
        #if os(iOS)
        loadCustomFont(name: "Roboto-Medium", fontExtension: "ttf")
        #endif
        testButton.setTitle(shortButtonText, for: .normal)
        testButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: smallFontSize)!
        testButton.sizeToFit()

        // move those to UIFontTests
        XCTAssertEqual(testButton.titleLabel?.font.lineHeight.rounded(), smallFontLineHeight)
        XCTAssertEqual(testButton.titleLabel?.font.fontName, "Roboto-Medium")

        let frameSizeWithShortLabelText = UIKit.CGSize(width: 28.5, height: 26.5)
        XCTAssertEqualWithAccuracy(testButton.frame.width, frameSizeWithShortLabelText.width, accuracy: 1.5)
        XCTAssertEqualWithAccuracy(testButton.frame.height, frameSizeWithShortLabelText.height, accuracy: 0.5)

        testButton.setTitle(mediumButtonText, for: .normal)
        testButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: mediumFontSize)!
        testButton.sizeToFit()
        testButton.titleLabel?.sizeToFit()

        let frameSizeWithMediumLabelText = UIKit.CGSize(width: 136.5, height: 31.0)
        XCTAssertEqualWithAccuracy(testButton.frame.width, frameSizeWithMediumLabelText.width, accuracy: 0.5)
        XCTAssertEqualWithAccuracy(testButton.frame.height, frameSizeWithMediumLabelText.height, accuracy: 0.1)
        XCTAssertEqual(testButton.titleLabel?.font.lineHeight.rounded(), mediumFontLineHeight)

        testButton.setTitle(longButtonText, for: .normal)
        testButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: largeFontSize)!
        testButton.sizeToFit()
        testButton.titleLabel?.sizeToFit()
        
        let frameSizeWithLongLabelText = UIKit.CGSize(width: 307.5, height: 36.0)
        XCTAssertEqualWithAccuracy(testButton.frame.width, frameSizeWithLongLabelText.width, accuracy: 1.5)
        XCTAssertEqualWithAccuracy(testButton.frame.height, frameSizeWithLongLabelText.height, accuracy: 0.1)
        XCTAssertEqual(testButton.titleLabel?.font.lineHeight.rounded(), largeFontLineHeight)
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

#if os(iOS)
func loadCustomFont(name: String, fontExtension: String) -> Bool {
    let fileManager = FileManager.default

    let bundleURL = Bundle.init(for: ButtonTests.self).bundleURL

    do {
        let contents = try fileManager.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: [], options: .skipsHiddenFiles)
        for url in contents {
            if url.pathExtension == fontExtension {
                let fontData = NSData(contentsOf: url)!
                let provider = CGDataProvider.init(data: fontData)!
                if let font = CGFont.init(provider) {
                    CTFontManagerRegisterGraphicsFont(font, nil)
                }
            }
        }
    } catch {
        print("error: \(error)")
    }
    return true
}
#endif
