//
//  UIFont.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL

private let systemFontName = "SomeSystemFont"

open class UIFont {
    public var fontName: String
    public var familyName: String?
    public var pointSize: CGFloat
    public var systemFontSize: CGFloat = 14 // random value, to be adjusted
    
    private let fontRenderer: FontRenderer
    
    private init?(name: String, size: CGFloat) {
        print("init font \(name) with size \(size)")
        self.fontName = name
        self.pointSize = size
        guard let fontRenderer = FontRenderer(name: fontName, size: size) else {
            return nil
        }
        self.fontRenderer = fontRenderer
    }
    
    public static func systemFont(ofSize fontSize: CGFloat) -> UIFont {
        // return system Font object in specified size
        return UIFont(name: systemFontName, size: fontSize)!
    }
}
