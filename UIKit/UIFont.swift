//
//  UIFont.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class UIFont {
    public var fontName: String
    public var familyName: String?
    public var pointSize: CGFloat
    public var systemFontSize: CGFloat = 14 // random value, to be adjusted
    var systemFont: String = "SomeSystemFont"
    
    init(name: String, size: CGFloat) {
        print("init font \(name) with size \(size)")
        self.fontName = name
        self.pointSize = size
    }
    
    public func systemFont(ofSize fontSize: CGFloat) -> UIFont {
        // return system Font object in specified size
        return UIFont(name: systemFont, size: fontSize)
    }
}
