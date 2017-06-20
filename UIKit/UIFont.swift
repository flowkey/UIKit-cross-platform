//
//  UIFont.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL

private let systemFontName = "Roboto-Regular.ttf"

open class UIFont {
    public var fontName: String
    public var familyName: String?
    public var pointSize: CGFloat
    public var systemFontSize: CGFloat = 14 // random value, to be adjusted
    
    private let renderer: FontRenderer
    
    private init?(name: String, size: CGFloat) {
        print("init font \(name) with size \(size)")
        self.fontName = name
        self.pointSize = size
        guard let fontRenderer = FontRenderer(name: fontName, size: size) else {
            return nil
        }
        self.renderer = fontRenderer
    }
    
    public static func systemFont(ofSize fontSize: CGFloat) -> UIFont {
        // return system Font object in specified size
        return UIFont(name: systemFontName, size: fontSize)!
    }
    
    internal func render(_ text: String?, color: UIColor, wrapLength: CGFloat = 0) -> Texture? {
        return renderer.render(text, color: color, wrapLength: Int(wrapLength))
    }
}
