//
//  FontLoader.swift
//  UIKit
//
//  Created by Geordie Jay on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL.ttf

private let contentScaleFactor: CGFloat = 2.0 // TODO: get and add correct contentScaleFactor according to device
private var loadedFontPointers = [FontPointer]()
private var customFontPaths = [String: String]()

private func initSDL_ttf() -> Bool {
    return (TTF_WasInit() == 1) || (TTF_Init() != -1) // TTF_Init returns -1 on failure
}

private struct FontPointer {
    let rawPointer: OpaquePointer
    let name: String
    let size: Int32

    init(_ rawPointer: OpaquePointer, name: String, size: Int32) {
        self.rawPointer = rawPointer
        self.name = name
        self.size = size
    }
}

internal class FontRenderer {
    let rawPointer: OpaquePointer // TTF_Font
    
    init?(name: String, size: Int32) {
        if let loadedPointer = loadFontPointerFromCacheIfPossible(name: name, size: size) {
            rawPointer = loadedPointer
        } else if let loadedFont = loadFontPointerFromDisk(name: name, size: size) {
            rawPointer = loadedFont
            loadedFontPointers.append(FontPointer(loadedFont, name: name, size: size))
        } else {
            return nil
        }
    }

    func getLineHeight() -> Int {
        return Int(CGFloat(TTF_FontLineSkip(rawPointer)) / contentScaleFactor)
    }

    func getFontFamilyName() -> String? {
        guard let cStringFamilyName = TTF_FontFaceFamilyName(rawPointer) else { return nil }
        let fontFamilyName = String(cString: cStringFamilyName)
        return fontFamilyName
    }

    func size(of text: String) -> CGSize {
        var width: Int32 = 0
        var height: Int32 = 0
        TTF_SizeUNICODE(rawPointer, text.toUTF16(), &width, &height)

        return CGSize(
            width: CGFloat(width) / contentScaleFactor,
            height: CGFloat(height) / contentScaleFactor
        )
    }

    public static func addCustomFont(name: String, path: String) {
        customFontPaths[name] = path
    }

    func render(_ text: String?, color: UIColor, wrapLength: Int = 0) -> Texture? {
        guard let text = text else { return nil }
        let unicode16Text = text.toUTF16()

        guard
            let surface = (wrapLength > 0) ?
                TTF_RenderUNICODE_Blended_Wrapped(rawPointer, unicode16Text, color.sdlColor, UInt32(wrapLength)) :
                TTF_RenderUNICODE_Blended(rawPointer, unicode16Text, color.sdlColor)
        else {
            return nil
        }

        defer { SDL_free(surface) }

        return Texture(surface: surface)
    }
}

private func loadFontPointerFromCacheIfPossible(name: String, size: Int32) -> OpaquePointer? {
    return loadedFontPointers.first(where: { $0.size == size })?.rawPointer
}

private func loadFontPointerFromDisk(name: String, size: Int32) -> OpaquePointer? {
    if !initSDL_ttf() { return nil }

    let adjustedFontSize = Int32(CGFloat(size) * contentScaleFactor)
    var pathToFontFile: String

    #if os(Android)
        // Android assets MUST have lowercase filenames:
        pathToFontFile = (androidAssetDir + name + ".ttf").lowercased()
    #else
        if let customPath = customFontPaths[name] {
            pathToFontFile = customPath
        } else {
            let UIKitBundle = Bundle.init(for: FontRenderer.self)
            pathToFontFile = UIKitBundle.path(forResource: name.lowercased(), ofType: ".ttf")!
        }
    #endif

    let rwOp = SDL_RWFromFile(pathToFontFile, "rb")

    guard let font = TTF_OpenFontRW(rwOp, 1, adjustedFontSize) else {
        print("no Font file found for \(name)")
        return nil
    }

    TTF_SetFontHinting(font, TTF_HINTING_LIGHT) // recommended in docs for max quality
    return font
}


private extension String {
    func toUTF16() -> [UInt16] {
        // Add a 0 to the end of the array to mark the end of the C string
        return self.utf16.map { $0 } + [0]
    }
}
