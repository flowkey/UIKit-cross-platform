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

open class UIFont: Hashable {
    private let fontFileName: String
    //public let fontName: String
    //public var familyName: String?
    public var pointSize: CGFloat
    public let lineHeight: CGFloat

    // These are the only public initializers for now:

    public static func boldSystemFont(ofSize size: CGFloat) -> UIFont {
        return systemFont(ofSize: size, weight: .UIFontWeightBold)
    }

    public static func systemFont(ofSize fontSize: CGFloat, weight: FontWeight = .UIFontWeightRegular) -> UIFont {
        return UIFont.fromCacheIfPossible(name: systemFontName + "-" + weight.rawValue, size: fontSize)!
    }
    
    public static func of(name: String, size: CGFloat) -> UIFont {
        return UIFont.fromCacheIfPossible(name: name, size: size)!
    }

    // MARK: Implementation details:

    /// Renderer is the interface to our rendering backend (at time of writing, SDL_ttf)
    /// If we ever want to change the backend, we should only have to change the FontRenderer class:
    fileprivate let renderer: FontRenderer

    internal func render(_ text: String?, color: UIColor, wrapLength: CGFloat = 0) -> Texture? {
        return renderer.render(text, color: color, wrapLength: Int(wrapLength))
    }

    public let hashValue: Int

    public static func == (lhs: UIFont, rhs: UIFont) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }


    // MARK: INITIALIZATION

    static var loadedFonts = Set<UIFont>()

    static fileprivate func fromCacheIfPossible(name fontFileName: String, size: CGFloat) -> UIFont? {
        if let cachedFont = UIFont.loadedFonts.first(where: { $0.fontFileName == fontFileName && $0.pointSize == size }) {
            return cachedFont
        } else if let loadedFont = UIFont(fromDiskWithFileName: fontFileName, size: size) {
            UIFont.loadedFonts.insert(loadedFont)
            return loadedFont
        } else {
            return nil
        }
    }

    // Don't use this directly, use `UIFont.of(name:size:)` instead to take advantage of caching!
    private init?(fromDiskWithFileName fontFileName: String, size: CGFloat) {
        guard let renderer = FontRenderer(name: fontFileName, size: size) else { return nil }
        self.renderer = renderer
        self.fontFileName = fontFileName
        self.pointSize = size
        self.lineHeight = CGFloat(renderer.getLineHeight())
        self.hashValue = fontFileName.hashValue ^ size.hashValue
    }
}


extension String {
    public func size(with font: UIFont) -> CGSize {
        return font.renderer.size(of: self)
    }
}
