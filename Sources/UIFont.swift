//
//  UIFont.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

private let systemFontName = "Roboto" // XXX: change this depending on platform?

open class UIFont {
    fileprivate static let contentScale: CGFloat = 2.0 // TODO: Get from Window

    fileprivate static var availableFontData: [String: CGDataProvider] = [:]
    static public var availableFonts: [String] {
        return Array(availableFontData.keys)
    }

    public let fontName: String
    public var familyName: String?
    public var pointSize: CGFloat
    public let lineHeight: CGFloat

    public struct Weight: RawRepresentable {
        public typealias RawValue = CGFloat
        public let rawValue: CGFloat

        public init?(rawValue: CGFloat) {
            switch rawValue {
            case -1 ..< -0.5: self.rawValue = -0.6
            case -0.5 ..< -0.2: self.rawValue = -0.4
            case -0.2 ..< 0.1: self.rawValue = 0.0
            case 0.1 ..< 0.3: self.rawValue = 0.2
            case 0.3 ..< 0.5: self.rawValue = 0.4
            case 0.5 ..< 1.0: self.rawValue = 0.62
            default: return nil
            }
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
            default: preconditionFailure()
            }
        }
    }

    public static func boldSystemFont(ofSize size: CGFloat) -> UIFont {
        return systemFont(ofSize: size, weight: Weight.bold)
    }

    public static func systemFont(ofSize size: CGFloat, weight: Weight = .regular) -> UIFont {
        return UIFont(name: systemFontName + "-" + weight.toString(), size: size)!
    }
 
    public init?(name: String, size: CGFloat) {
        let name = name.lowercased()
        guard let fontData = UIFont.availableFontData[name] else {
            print("Tried to load \(name) but it wasn't in UIFont.availableFonts")
            return nil
        }

        guard let renderer = FontRenderer(fontData, size: Int32(size * UIFont.contentScale)) else {
            print("Couldn't load font", name)
            return nil
        }

        self.renderer = renderer
        self.fontName = name
        self.familyName = renderer.getFontFamilyName() ?? "<unknown>"
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

extension String {
    public func size(with font: UIFont) -> CGSize {
        let unscaledSize = font.renderer.size(of: self)
        return CGSize(
            width: unscaledSize.width / UIFont.contentScale,
            height: unscaledSize.height / UIFont.contentScale
        )
    }
}
