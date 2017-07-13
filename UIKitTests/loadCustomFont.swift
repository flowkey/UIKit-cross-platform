//
//  loadCustomFont.swift
//  UIKitTests
//
//  Created by Chris on 13.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import UIKit

func loadCustomFont(name: String, fontExtension: String) -> Bool {
    let fileManager = FileManager.default

    let bundleURL = Bundle.init(identifier: "com.flowkey.UIKit.iOSTestTarget")!.bundleURL

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
