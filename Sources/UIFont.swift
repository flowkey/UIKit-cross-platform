//
//  UIFont.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class UIFont {
    public let fontName: String
    public var familyName: String? {
        return renderer?.getFontFamilyName()
    }
    public var pointSize: CGFloat
    public var lineHeight: CGFloat {
        return CGFloat(renderer?.getLineHeight() ?? 0) / UIScreen.lastKnownScale
    }

    /**
        Change this value after loading the desired system font via `UIFont.loadFont(fromPath: String)`.
        Note: The name you provide here is `.fontName` of the loaded `UIFont` instance. We can't set a
        `UIFont` as the value here, because each `UIFont` is associated with a size. `CGFont` would be a
        better level of abstraction for that reason, but we haven't implemented it (yet?)
     */
    public internal(set) static var systemFontFamilyName = "Roboto"

    public static func boldSystemFont(ofSize size: CGFloat) -> UIFont {
        return systemFont(ofSize: size, weight: Weight.bold)
    }

    public static func systemFont(ofSize size: CGFloat, weight: Weight = .regular) -> UIFont {
        return UIFont(name: systemFontFamilyName + "-" + weight.toString(), size: size)!
    }

    public init?(name: String, size: CGFloat) {
        let name = name.lowercased()
        let size = Int32(size * UIScreen.lastKnownScale)

        self.fontName = name
        self.pointSize = CGFloat(size)
    }

    // MARK: Implementation details:

    /// Renderer is the interface to our rendering backend (at time of writing, SDL_ttf)
    /// If we ever want to change the backend, we should only have to change the FontRenderer class:
    fileprivate var renderer: FontRenderer? {
        // We access the renderer from the cache every time because it may have been replaced since this UIFont was inited
        guard let fontData = UIFont.cachedFontFiles[fontName] else {
            print("Tried to load \(fontName) but it wasn't in UIFont.__availableFonts: \(UIFont.cachedFontFiles)")
            return nil
        }

        let cacheKey = fontName + String(describing: pointSize)

        if let renderer = FontRenderer.cache[cacheKey] {
            return renderer
        }

        guard let newlyLoadedRenderer = FontRenderer(fontData, size: Int32(pointSize)) else {
            return nil
        }

        FontRenderer.cache[cacheKey] = newlyLoadedRenderer
        return newlyLoadedRenderer
    }

    internal func render(_ text: String?, color: UIColor, wrapLength: CGFloat = 0) -> CGImage? {
        return renderer?.render(text, color: color, wrapLength: Int(wrapLength * UIScreen.lastKnownScale))
    }

    internal func render(_ attributedString: NSAttributedString?, color: UIColor, wrapLength: CGFloat = 0) -> CGImage? {
        return renderer?.render(attributedString, color: color)
    }
}

// MARK: Caches
extension UIFont {
    /// We store the TTF files we load into memory so we can quickly make more `FontRenderer` instances.
    private static var cachedFontFiles: [String: CGDataProvider] = [:]

    /// We call this when deinitialising the UIApplication to recover the memory they used
    static func clearCachedFontFiles() {
        cachedFontFiles.removeAll()
    }

    /// A list of Fonts loaded by and available to UIKit Cross Platform.
    /// Note: this API is subject to change.
    static public var __availableFonts: [String] {
        return Array(cachedFontFiles.keys)
    }
}

extension UIFont: Equatable {
    public static func == (lhs: UIFont, rhs: UIFont) -> Bool {
        return lhs.fontName == rhs.fontName && lhs.pointSize == rhs.pointSize
    }
}

extension UIFont {
    public struct Weight: RawRepresentable {
        public typealias RawValue = CGFloat
        public let rawValue: CGFloat

        public init?(rawValue: CGFloat) {
            self.rawValue = rawValue
        }

        public static let thin = Weight(rawValue: -0.6)!
        public static let light = Weight(rawValue: -0.4)!
        public static let regular = Weight(rawValue: 0.0)!
        public static let medium = Weight(rawValue: 0.23)!
        public static let semibold = Weight(rawValue: 0.3)!
        public static let bold = Weight(rawValue: 0.4)!
        public static let black = Weight(rawValue: 0.62)!

        public func toString() -> String {
            switch self.rawValue {
            case -1 ..< -0.5: return "thin"
            case -0.5 ..< -0.2: return "light"
            case -0.2 ..< 0.1: return "regular"
            case 0.1 ..< 0.3: return "medium"
            case 0.3 ..< 0.5: return "bold"
            case 0.5 ..< 1.0: return "black"
            default: preconditionFailure("Invalid font weight. Value must be between -1 and 1")
            }
        }
    }
}

extension UIFont {
    public enum LoadingError: Error {
        case couldNotOpenDataFile, couldNotDecodeFont
    }

    internal static func loadSystemFonts() {
        Bundle(for: UIFont.self).paths(forResourcesOfType: "ttf", inDirectory: nil).forEach { path in
            (try? setSystemFont(fromPath: path)) ?? print("Couldn't load font from \(path)")
        }
    }

    @discardableResult
    public static func loadFont(fromPath path: String) throws -> FontRenderer {
        guard let dataProvider = CGDataProvider(filepath: path) else {
            throw LoadingError.couldNotOpenDataFile
        }

        guard let fontRenderer = FontRenderer(dataProvider, size: 0) else {
            throw LoadingError.couldNotDecodeFont
        }

        let fontFamilyName = fontRenderer.getFontFamilyName() ?? "unknown"
        let fontStyleName = fontRenderer.getFontStyleName() ?? "unknown"
        let fontName = "\(fontFamilyName)-\(fontStyleName)".lowercased()

        UIFont.cachedFontFiles[fontName] = dataProvider

        return fontRenderer
    }

    public static func setSystemFont(fromPath path: String) throws {
        systemFontFamilyName = try loadFont(fromPath: path).getFontFamilyName()!
    }
}

extension NSAttributedString {
    public func size(with font: UIFont, wrapLength: CGFloat = 0) -> CGSize {
        guard let renderer = font.renderer else { return .zero }
        return wrapLength == 0 ?
            renderer.singleLineSize(of: self) / UIScreen.lastKnownScale :
            string.size(with: font, wrapLength: wrapLength) // fallback to String.size for multiline text
    }
}

extension String {
    public func size(with font: UIFont, wrapLength: CGFloat = 0) -> CGSize {
        guard let renderer = font.renderer else { return .zero }

        let retinaResolutionSize =
            (wrapLength <= 0) ? // a wrapLength of < 0 leads to a crash, so assume 0
                renderer.singleLineSize(of: self) :
                renderer.multilineSize(
                    of: self,
                    wrapLength: UInt(wrapLength * UIScreen.lastKnownScale)
                )

        return retinaResolutionSize / UIScreen.lastKnownScale
    }
}
