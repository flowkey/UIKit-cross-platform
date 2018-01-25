//
//  loadCustomFont.swift
//  UIKitTests
//
//  Created by Chris on 13.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import UIKit

// wrap this in a class which we can use to find "this" bundle
class FontLoader {
    static func loadBundledFonts() {
        Bundle(for: FontLoader.self)
            .urls(forResourcesWithExtension: "ttf", subdirectory: nil)?
            .forEach { url in
                let fontData = NSData(contentsOf: url)!
                let provider = CGDataProvider(data: fontData)!
                if let font = CGFont(provider) {
                    CTFontManagerRegisterGraphicsFont(font, nil)
                } else {
                    print("Failed to load \(url.absoluteString)")
                }
        }
    }
}
