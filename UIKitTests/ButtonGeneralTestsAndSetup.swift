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

public typealias CGSize = UIKit.CGSize
public typealias CGFloat = UIKit.CGFloat
public typealias CGPoint = UIKit.CGPoint

let shortButtonText = "Short"
let mediumButtonText = "MediumButtonText"
let longButtonText = "ThisIsALongTextToTestTheButton"

let smallFontSize: CGFloat = 12
let smallFontLineHeight: CGFloat = 14
let mediumFontSize: CGFloat = 16 // default
let mediumFontLineHeight: CGFloat = 19
let largeFontSize: CGFloat = 20
let largeFontLineHeight: CGFloat = 23

let defaultLabelVerticalPadding: CGFloat = 6

let smallImageSize = CGSize(width: 40, height: 40)
let mediumImageSize = CGSize(width: 80, height: 80)
let largeImageSize = CGSize(width: 150, height: 150)

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

func createTestImage(ofSize imageSize: CGSize) -> UIImage {
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
        convenience init?(size: CGSize) {
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

    let bundleURL = Bundle.init(for: ButtonGeneralTestsAndSetup.self).bundleURL

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
