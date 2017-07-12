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

    let defaultLabelVerticalPadding: UIKit.CGFloat = 6

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
        testButton.setImage(nil, for: .normal)
        super.tearDown()
    }

    func testSetTitle() {
        testButton.setTitle(shortButtonText, for: .normal)
        testButton.layoutSubviews()
        XCTAssertEqual(testButton.titleLabel?.text, shortButtonText)

        testButton.setTitle(mediumButtonText, for: .normal)
        testButton.layoutSubviews()
        XCTAssertEqual(testButton.titleLabel?.text, mediumButtonText)

        testButton.setTitle(longButtonText, for: .normal)
        testButton.layoutSubviews()
        XCTAssertEqual(testButton.titleLabel?.text, longButtonText)
    }

    func testSizeToFitWithNoLabelAndNoImage () {
        let defaultSizeForEmptyButton = UIKit.CGSize(width: 30.0, height: 34.0)
        testButton.sizeToFit()
        XCTAssertEqual(testButton.frame.size, defaultSizeForEmptyButton)
    }

    func testSizeToFitWithLabel() {
        #if os(iOS)
        loadCustomFont(name: "Roboto-Medium", fontExtension: "ttf")
        #endif
        testButton.setTitle(shortButtonText, for: .normal)
        testButton.layoutSubviews()
        testButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: smallFontSize)!
        testButton.sizeToFit()

        // move those to UIFontTests
        XCTAssertEqual(testButton.titleLabel?.font.lineHeight.rounded(), smallFontLineHeight)
        XCTAssertEqual(testButton.titleLabel?.font.fontName, "Roboto-Medium")

        let frameSizeWithShortLabelText = UIKit.CGSize(width: 28.5, height: 26.5)
        XCTAssertEqualWithAccuracy(testButton.frame.width, frameSizeWithShortLabelText.width, accuracy: 1.5)
        XCTAssertEqualWithAccuracy(testButton.frame.height, frameSizeWithShortLabelText.height, accuracy: 0.5)

        testButton.setTitle(mediumButtonText, for: .normal)
        testButton.layoutSubviews()
        testButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: mediumFontSize)!
        testButton.sizeToFit()

        let frameSizeWithMediumLabelText = UIKit.CGSize(width: 136.5, height: 31.0)
        XCTAssertEqualWithAccuracy(testButton.frame.width, frameSizeWithMediumLabelText.width, accuracy: 0.5)
        XCTAssertEqualWithAccuracy(testButton.frame.height, frameSizeWithMediumLabelText.height, accuracy: 0.1)
        XCTAssertEqual(testButton.titleLabel?.font.lineHeight.rounded(), mediumFontLineHeight)

        testButton.setTitle(longButtonText, for: .normal)
        testButton.layoutSubviews()
        testButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: largeFontSize)!
        testButton.sizeToFit()
        
        let frameSizeWithLongLabelText = UIKit.CGSize(width: 307.5, height: 36.0)
        XCTAssertEqualWithAccuracy(testButton.frame.width, frameSizeWithLongLabelText.width, accuracy: 1.5)
        XCTAssertEqualWithAccuracy(testButton.frame.height, frameSizeWithLongLabelText.height, accuracy: 0.1)
        XCTAssertEqual(testButton.titleLabel?.font.lineHeight.rounded(), largeFontLineHeight)
    }

    func testSizeToFitWithImage() {
        testButton.setImage(createTestImage(ofSize: mediumImageSize), for: .normal)
        testButton.layoutSubviews()
        testButton.sizeToFit()
        XCTAssertEqual(testButton.frame.size, mediumImageSize)
    }

    func testContentAlignmentWithOnlyLabel() {
        let buttonFrameSize = UIKit.CGSize(width: 200, height: 100)
        #if os(iOS)
            loadCustomFont(name: "Roboto-Medium", fontExtension: "ttf")
        #endif
        testButton.setTitle(shortButtonText, for: .normal)
        testButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: smallFontSize)!
        testButton.sizeToFit()
        testButton.frame = CGRect(origin: testButton.frame.origin, size: buttonFrameSize)
        testButton.layoutSubviews()

        XCTAssertEqual(testButton.contentHorizontalAlignment, UIControlContentHorizontalAlignment.center)
        XCTAssertEqual(testButton.contentVerticalAlignment, UIControlContentVerticalAlignment.center)
        XCTAssertEqualWithAccuracy((testButton.titleLabel?.frame.origin.x)!, buttonFrameSize.width / 2 - (testButton.titleLabel?.frame.width)! / 2, accuracy: 0.01)
        XCTAssertEqualWithAccuracy((testButton.titleLabel?.frame.origin.y)!, buttonFrameSize.height / 2 - (testButton.titleLabel?.frame.height)! / 2, accuracy: 0.18)

        testButton.contentHorizontalAlignment = .left
        testButton.contentVerticalAlignment = .top
        testButton.layoutSubviews()
        XCTAssertEqual(testButton.contentHorizontalAlignment, UIControlContentHorizontalAlignment.left)
        XCTAssertEqual(testButton.contentVerticalAlignment, UIControlContentVerticalAlignment.top)
        XCTAssertEqual(testButton.titleLabel?.frame.origin.x, 0.0)
        XCTAssertEqualWithAccuracy((testButton.titleLabel?.frame.origin.y)!, defaultLabelVerticalPadding, accuracy: 0.001)

        testButton.contentHorizontalAlignment = .right
        testButton.contentVerticalAlignment = .bottom
        testButton.layoutSubviews()
        XCTAssertEqual(testButton.contentHorizontalAlignment, UIControlContentHorizontalAlignment.right)
        XCTAssertEqual(testButton.contentVerticalAlignment, UIControlContentVerticalAlignment.bottom)
        XCTAssertEqual(testButton.titleLabel?.frame.origin.x, buttonFrameSize.width - (testButton.titleLabel?.frame.width)!)
        XCTAssertEqual(testButton.titleLabel?.frame.origin.y, buttonFrameSize.height - (testButton.titleLabel?.frame.height)! - defaultLabelVerticalPadding)
    }

    func testContentAlignmentWithOnlyImage() {
        let testImageSize = UIKit.CGSize(width: 40, height: 40)
        let buttonFrameSize = UIKit.CGSize(width: 200, height: 100)

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
        #if os(iOS)
            loadCustomFont(name: "Roboto-Medium", fontExtension: "ttf")
        #endif
        testButton.setTitle(shortButtonText, for: .normal)
        testButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: smallFontSize)!

        let testImageSize = UIKit.CGSize(width: 30, height: 30)
        let buttonFrameSize = UIKit.CGSize(width: 200, height: 100)

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

func createTestImage(ofSize imageSize: UIKit.CGSize) -> UIImage {
    var testImage: UIImage
    #if os(iOS)
        UIGraphicsBeginImageContext(imageSize)
        testImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
    #else
        testImage = UIImage(texture: Texture(size: imageSize)!)
    #endif
    return testImage
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
