//
//  FontLoader.swift
//  UIKit
//
//  Created by Geordie Jay on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL.ttf

private func initSDL_ttf() -> Bool {
    return (TTF_WasInit() == 1) || (TTF_Init() != -1) // TTF_Init returns -1 on failure
}

internal class FontRenderer {
    private let rawPointer: OpaquePointer // TTF_Font

    init?(_ source: CGDataProvider, size: Int32) {
        if !initSDL_ttf() { return nil }

        let rwOp = SDL_RWFromConstMem(source.data, Int32(source.data.count))
        guard let font = TTF_OpenFontRW(rwOp, 1, size) else { return nil }

        TTF_SetFontHinting(font, TTF_HINTING_LIGHT) // recommended in docs for max quality
        rawPointer = font
    }

    func getLineHeight() -> Int {
        return Int(TTF_FontLineSkip(rawPointer))
    }

    func getFontStyleName() -> String? {
        guard let styleName = TTF_FontFaceStyleName(rawPointer) else { return nil }
        return String(cString: styleName)
    }

    func getFontFamilyName() -> String? {
        guard let cStringFamilyName = TTF_FontFaceFamilyName(rawPointer) else { return nil }
        return String(cString: cStringFamilyName)
    }

    func size(of text: String) -> CGSize {
        var width: Int32 = 0
        var height: Int32 = 0
        TTF_SizeUNICODE(rawPointer, text.toUTF16(), &width, &height)

        return CGSize(width: CGFloat(width), height: CGFloat(height))
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

private extension String {
    func toUTF16() -> [UInt16] {
        // Add a 0 to the end of the array to mark the end of the C string
        return self.utf16.map { $0 } + [0]
    }
}
