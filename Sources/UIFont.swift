//
//  UIFont.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

private let systemFontName = "Roboto" // XXX: change this depending on platform?

open class UIFont: Equatable {
    static var fontRendererCache = [String: FontRenderer]()

    public static func == (lhs: UIFont, rhs: UIFont) -> Bool {
        return lhs.fontName == rhs.fontName && lhs.pointSize == rhs.pointSize
    }

    fileprivate static var availableFontData: [String: CGDataProvider] = [:]
    static public var availableFonts: [String] {
        return Array(availableFontData.keys)
    }

    public let fontName: String
    public var familyName: String?
    public var pointSize: CGFloat
    public let lineHeight: CGFloat

    public static func boldSystemFont(ofSize size: CGFloat) -> UIFont {
        return systemFont(ofSize: size, weight: Weight.bold)
    }

    public static func systemFont(ofSize size: CGFloat, weight: Weight = .regular) -> UIFont {
        return UIFont(name: systemFontName + "-" + weight.toString(), size: size)!
    }

    public init?(name: String, size: CGFloat) {
        let name = name.lowercased()
        let size = Int32(size * UIScreen.main.scale)

        guard let fontData = UIFont.availableFontData[name] else {
            print("Tried to load \(name) but it wasn't in UIFont.availableFonts")
            return nil
        }

        let cacheKey = name + String(describing: size)
        guard let renderer = UIFont.fontRendererCache[cacheKey] ?? FontRenderer(fontData, size: size) else {
            print("Couldn't load font", name)
            return nil
        }

        UIFont.fontRendererCache[cacheKey] = renderer
        self.renderer = renderer
        self.fontName = name
        self.familyName = renderer.getFontFamilyName() ?? "<unknown>"
        self.pointSize = CGFloat(size)
        self.lineHeight = CGFloat(renderer.getLineHeight()) / UIScreen.main.scale
    }

    // MARK: Implementation details:

    /// Renderer is the interface to our rendering backend (at time of writing, SDL_ttf)
    /// If we ever want to change the backend, we should only have to change the FontRenderer class:
    fileprivate let renderer: FontRenderer

    internal func render(_ text: String?, color: UIColor, wrapLength: CGFloat = 0) -> CGImage? {
        return renderer.render(text, color: color, wrapLength: Int(wrapLength * UIScreen.main.scale))
    }

    internal func render(_ attributedString: NSAttributedString?, color: UIColor, wrapLength: CGFloat = 0) -> CGImage? {
        return renderer.render(attributedString, color: color)
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
            (try? loadFont(fromPath: path)) ?? print("Couldn't load font from \(path)")
        }
    }

    public static func loadFont(fromPath path: String) throws {
        guard let dataProvider = CGDataProvider(filepath: path) else {
            throw LoadingError.couldNotOpenDataFile
        }

        guard let tempRenderer = FontRenderer(dataProvider, size: 0) else {
            throw LoadingError.couldNotDecodeFont
        }

        let fontStyleName = tempRenderer.getFontStyleName() ?? "unknown"
        let fontFamilyName = tempRenderer.getFontFamilyName() ?? "unknown"
        let fontName = "\(fontFamilyName)-\(fontStyleName)".lowercased()

        UIFont.availableFontData[fontName] = dataProvider
    }
}

extension NSAttributedString {
    public func size(with font: UIFont, wrapLength: CGFloat = 0) -> CGSize {

        return wrapLength == 0 ?
            font.renderer.singleLineSize(of: self) / UIScreen.main.scale :
            string.size(with: font, wrapLength: wrapLength) // fallback to String.size for multiline text
    }
}

extension String {
    public func size(with font: UIFont, wrapLength: CGFloat = 0) -> CGSize {
        let retinaResolutionSize =
            (wrapLength <= 0) ? // a wrapLength of < 0 leads to a crash, so assume 0
                font.renderer.singleLineSize(of: self) :
                font.renderer.multilineSize(
                    of: self,
                    wrapLength: UInt(wrapLength * UIScreen.main.scale)
                )

        return retinaResolutionSize / UIScreen.main.scale
    }
}
