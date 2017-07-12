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

class ButtonGeneralTestsAndSetup: XCTestCase {
    let testButton = Button(frame: .zero)

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        testButton.setTitle(nil, for: .normal)
        testButton.setImage(nil, for: .normal)
        testButton.frame = .zero
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

#if os(iOS)
public class Button: UIButton {
    var image: UIImage? {
        didSet {
            setImage(image, for: .normal)
            setImage(image, for: .highlighted)
        }
    }

    public var onPress: (() -> Void)? {
        didSet {
            if onPress != nil {
                // The docs say it is safe to add the same target/action multiple times:
                addTarget(self, action: #selector(handleOnPress), for: .touchUpInside)
            } else {
                removeTarget(self, action: #selector(handleOnPress), for: .touchUpInside)
            }
        }
    }

    @objc private func handleOnPress() {
        onPress?()
    }
}
#endif
