//
//  FontLoader.swift
//  UIKit
//
//  Created by Geordie Jay on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL.ttf

let contentScaleFactor = 2.0 // TODO: get and add correct contentScaleFactor according to device

let macSourcesDir: String = String(#file.characters.dropLast("FontRenderer.swift".characters.count)) + ".."

func initSDL_ttf() -> Bool {
    return (TTF_WasInit() == 1) || (TTF_Init() != -1) // TTF_Init returns -1 on failure
}

internal class FontRenderer {
    let rawPointer: OpaquePointer
    static var loadedFontPointerDict = [String: OpaquePointer]()
    
    init(name: String, size: CGFloat) {
        let adjustedFontSize = Int32(size * contentScaleFactor)
        if let loadedPointer = FontRenderer.loadFontPointerFromCacheIfPossible(fontName: name, size: adjustedFontSize) {
            rawPointer = loadedPointer
        } else {
            fatalError("no font found for \(name) of size \(size)")
        }
    }
    
    static fileprivate func loadFontPointerFromCacheIfPossible(fontName: String, size: Int32) -> OpaquePointer? {
        let fontIdentifier = fontName + String(size)
        if let cachedFontPointer = FontRenderer.loadedFontPointerDict[fontIdentifier] {
            return cachedFontPointer
        } else if let newFontPointer = FontRenderer.loadFontPointerFromDisk(fileName: fontName, fontSize: size) {
            loadedFontPointerDict[fontIdentifier] = newFontPointer
            return newFontPointer
        } else {
            return nil
        }
    }
    
    static fileprivate func loadFontPointerFromDisk(fileName: String, fontSize: Int32) -> OpaquePointer? {
        if initSDL_ttf() == false { return nil }
        
        let resourcesDir = macSourcesDir + "/Resources/"
        let pathToFontFile = resourcesDir + fileName + ".ttf"
        let rwOp = SDL_RWFromFile(pathToFontFile, "rb")
        
        guard let font = TTF_OpenFontRW(rwOp, 1, fontSize) else { return nil }
        TTF_SetFontHinting(font, TTF_HINTING_LIGHT) // recommended in docs for max quality
        
        return font
    }

    func getLineHeight() -> Int {
        return Int(Double(TTF_FontLineSkip(rawPointer)) / contentScaleFactor)
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

        return Texture(surface: surface)
    }
}


private extension String {
    func toUTF16() -> [UInt16] {
        // Add a 0 to the end of the array to mark the end of the C string
        return self.utf16.map { $0 } + [0]
    }
}
