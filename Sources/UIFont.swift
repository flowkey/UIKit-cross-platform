//
//  UIFont.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL

private let systemFontName = "Roboto" // XXX: change this depending on platform?

public enum FontWeight: String {
    case UIFontWeightThin = "Thin"
    case UIFontWeightLight = "Light"
    case UIFontWeightRegular = "Regular"
    case UIFontWeightMedium = "Medium"
    case UIFontWeightBold = "Bold"
    case UIFontWeightBlack = "Black"
}

open class UIFont {
    public var fontName: String
    public var familyName: String?
    public var pointSize: CGFloat
    public let lineHeight: CGFloat

    // These are the only public initializers for now:

    public static func boldSystemFont(ofSize size: CGFloat) -> UIFont {
        return systemFont(ofSize: size, weight: .UIFontWeightBold)
    }

    public static func systemFont(ofSize fontSize: CGFloat, weight: FontWeight = .UIFontWeightRegular) -> UIFont {
        return UIFont(name: systemFontName + "-" + weight.rawValue, size: fontSize)!
    }
    
    public init?(name fontFileName: String, size: CGFloat) {
        guard let renderer = FontRenderer(name: fontFileName, size: Int32(size)) else {
            print("Couldn't load font", fontFileName)
            return nil
        }

        self.renderer = renderer
        self.fontName = fontFileName
        self.familyName = renderer.getFontFamilyName()
        self.pointSize = size
        self.lineHeight = CGFloat(renderer.getLineHeight())
    }

    // MARK: Implementation details:

    /// Renderer is the interface to our rendering backend (at time of writing, SDL_ttf)
    /// If we ever want to change the backend, we should only have to change the FontRenderer class:
    fileprivate let renderer: FontRenderer

    internal func render(_ text: String?, color: UIColor, wrapLength: CGFloat = 0) -> Texture? {
        return renderer.render(text, color: color, wrapLength: Int(wrapLength))
    }
}


extension String {
    public func size(with font: UIFont) -> CGSize {
        return font.renderer.size(of: self)
    }
}
